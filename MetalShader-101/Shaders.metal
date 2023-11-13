#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

#import "hsv_header.metal"


[[ stitchable ]] float2 pixellate(float2 position, float size) {
    float2 pixellatedPosition = round(position / size) * size;
    return pixellatedPosition;
}



[[ stitchable ]] float2 wave(float2 position, float time, float speed, float frequency, float amplitude) {
    float positionY = position.y + sin((time * speed) + (position.x / frequency)) * amplitude;
    return float2(position.x, positionY);
}

[[ stitchable ]] half4 grayscale(float2 position, SwiftUI::Layer layer) {
    half4 originalColor = layer.sample(position);
    float grayscaleValue = (originalColor.r + originalColor.g + originalColor.b) / 3.0;
    return half4(grayscaleValue, grayscaleValue, grayscaleValue, originalColor.a);
}


struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinates [[user(texturecoord)]];
};


[[ stitchable ]]  float4 gaussianBlurFragment(VertexOut fragmentIn [[ stage_in ]],
                                     texture2d<float, access::sample> texture [[texture(0)]]) {
    float2 offset = fragmentIn.textureCoordinates;
    constexpr sampler qsampler(coord::normalized,
                               address::clamp_to_edge);
//    float4 color = texture.sample(qsampler, coordinates);
    float width = texture.get_width();
    float height = texture.get_width();
    float xPixel = (1 / width) * 3;
    float yPixel = (1 / height) * 2;
    
    
    float3 sum = float3(0.0, 0.0, 0.0);
    
    
    // code from https://github.com/mattdesl/lwjgl-basics/wiki/ShaderLesson5
    
    // 9 tap filter
    sum += texture.sample(qsampler, float2(offset.x - 4.0*xPixel, offset.y - 4.0*yPixel)).rgb * 0.0162162162;
    sum += texture.sample(qsampler, float2(offset.x - 3.0*xPixel, offset.y - 3.0*yPixel)).rgb * 0.0540540541;
    sum += texture.sample(qsampler, float2(offset.x - 2.0*xPixel, offset.y - 2.0*yPixel)).rgb * 0.1216216216;
    sum += texture.sample(qsampler, float2(offset.x - 1.0*xPixel, offset.y - 1.0*yPixel)).rgb * 0.1945945946;
    
    sum += texture.sample(qsampler, offset).rgb * 0.2270270270;
    
    sum += texture.sample(qsampler, float2(offset.x + 1.0*xPixel, offset.y + 1.0*yPixel)).rgb * 0.1945945946;
    sum += texture.sample(qsampler, float2(offset.x + 2.0*xPixel, offset.y + 2.0*yPixel)).rgb * 0.1216216216;
    sum += texture.sample(qsampler, float2(offset.x + 3.0*xPixel, offset.y + 3.0*yPixel)).rgb * 0.0540540541;
    sum += texture.sample(qsampler, float2(offset.x + 4.0*xPixel, offset.y + 4.0*yPixel)).rgb * 0.0162162162;
    
    float4 adjusted;
    adjusted.rgb = sum;
//    adjusted.g = color.g;
    adjusted.a = 1;
    return adjusted;
}

[[ stitchable ]] half4 circleBlur(float2 position, SwiftUI::Layer layer, float2 size, float radius, float sampleCount) {
    
    half4 color = 0.0;
    for (int i = 0; i < int(sampleCount); ++i) {
        float fraction = float(i) / sampleCount;
        float x = position.x;
        float y = position.y;
        float angle = fraction * M_PI_F * 2;
        x += cos(angle) * radius;
        y += sin(angle) * radius;
        color += layer.sample(float2(x, y));
    }
    color /= float(sampleCount);

    return color;
}

[[ stitchable ]] half4 chromaKey(float2 position,
                                 half4 color,
                                 half4 keyColor,
                                 float range,
                                 float softness,
                                 float edgeDesaturation,
                                 float alphaCrop) {
    
    float3 ck_hsv = rgb2hsv(keyColor.r, keyColor.g, keyColor.b);
    
    float4 c = float4(color);
    
    float3 c_hsv = rgb2hsv(c.r, c.g, c.b);
    
    float ck_h = abs(c_hsv[0] - ck_hsv[0]) - range;
    
    float ck = (ck_h + (softness) / 2) / softness;
    if (ck < 0.0) {
        ck = 0.0;
    } else if (ck > 1.0) {
        ck = 1.0;
    }
    
    ck = max(ck, 1.0 - c_hsv[1]);
    ck = max(ck, 1.0 - c_hsv[2]);
    
    float edge_sat = 1 - edgeDesaturation;
    if (edge_sat < 0) { edge_sat = 0; }
    else if (edge_sat > 1) { edge_sat = 1; }
    c_hsv[1] *= mix(edge_sat, 1.0, pow(ck, 10));
    
    float3 ck_c = hsv2rgb(c_hsv[0], c_hsv[1], c_hsv[2]);
    
    float invertedAlphaCrop = 1.0 - min(1.0, max(0.0, alphaCrop));
    ck = min(1.0, max(0.0, 1.0 - ((1.0 - ck) / invertedAlphaCrop)));
    
    // premultiply
    ck_c *= ck;
    
    float a = ck * c.a;
    
    return half4(ck_c.r, ck_c.g, ck_c.b, a);
}
