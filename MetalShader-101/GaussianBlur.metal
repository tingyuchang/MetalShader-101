#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 blur(float2 position, SwiftUI::Layer layer, float2 size) {
    float Pi = 6.28318530718; // Pi*2
    
    // GAUSSIAN BLUR SETTINGS {{{
    float Directions = 16.0; // BLUR DIRECTIONS (Default 16.0 - More is better but slower)
    float Quality = 3.0; // BLUR QUALITY (Default 4.0 - More is better but slower)
    float Size = 8.0; // BLUR SIZE (Radius)
    // GAUSSIAN BLUR SETTINGS }}}
    
    float2 Radius = Size/size.xy;
    // float2 uv = position/size.xy;
    // layer.sample(<#float2 p#>)
    half4 Color = layer.sample(float2(1));
    
    // Blur calculations
    for( float d=0.0; d<Pi; d+=Pi/Directions)
    {
       for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality)
       {
           Color += layer.sample(float2(cos(d), sin(d)) * Radius * i);
       }
    }
    
    // Output to screen
    Color /= Quality * Directions - 15.0;
    return  layer.sample(float2(0.2));
}


// Circle Blur
[[ stitchable ]] half4 gaussianBlur(float2 pos, SwiftUI::Layer layer, float2 size, float blur) {
    
    float Pi = 6.28318530718; // Pi*2
    // GAUSSIAN BLUR SETTINGS {{{
    float Directions = 16.0; // BLUR DIRECTIONS (Default 16.0 - More is better but slower)
    float Quality = 3.0; // BLUR QUALITY (Default 4.0 - More is better but slower)
    // float Size = 8.0; // BLUR SIZE (Radius)
    // GAUSSIAN BLUR SETTINGS }}}
    
    // float2 radius = Size/size;
    float2 uv = pos/size;
    // half4 originalColor = layer.sample(position);
    half4 originalColor = layer.sample(pos);
    
    
    // Blur calculations
    for( float d = 0.0; d < Pi; d += Pi/Directions) {
        for(float i = 1.0 / Quality; i <= 1.0; i += 1.0 / Quality) {
//            originalColor += layer.sample(uv+float2(cos(d), sin(d))* radius * i);
            float x = pos.x;
            float y = pos.y;
//            x += uv.x + cos(d) * radius.x * i;
//            y += uv.y + sin(d) * radius.y * i;
//            x += uv.x + cos(d) * blur * (1 - pos.y/size.y);
//            y += uv.y + sin(d) * blur * (1 - pos.y/size.y);
            x += uv.x + cos(d) * blur;
            y += uv.y + sin(d) * blur;
            originalColor += layer.sample(float2(x, y));
        }
    }
   
    // Output to screen
    originalColor /= Quality * Directions - 15.0;
    return originalColor;
}

// from github
[[ stitchable ]] half4 gaussianBlur_1(float2 pos, SwiftUI::Layer layer, float2 size, float radius) {
    float2 offset = pos/size;

    float width = size.x;
    float height = size.y;
    float xPixel = (1 / width) * 3;
    float yPixel = (1 / height) * 2;
    
    half4 sum = layer.sample(pos);
    
    // 9 tap filter
    sum += layer.sample(float2(offset.x - 4.0*xPixel*radius, offset.y - 4.0*yPixel*radius)) * 0.0162162162;
    sum += layer.sample(float2(offset.x - 3.0*xPixel*radius, offset.y - 3.0*yPixel*radius)) * 0.0540540541;
    sum += layer.sample(float2(offset.x - 2.0*xPixel*radius, offset.y - 2.0*yPixel*radius)) * 0.1216216216;
    sum += layer.sample(float2(offset.x - 1.0*xPixel*radius, offset.y - 1.0*yPixel*radius)) * 0.1945945946;
    
    sum += layer.sample(offset) * 0.2270270270;
    
    sum += layer.sample(float2(offset.x + 1.0*xPixel*radius, offset.y + 1.0*yPixel*radius)) * 0.1945945946;
    sum += layer.sample(float2(offset.x + 2.0*xPixel*radius, offset.y + 2.0*yPixel*radius)) * 0.1216216216;
    sum += layer.sample(float2(offset.x + 3.0*xPixel*radius, offset.y + 3.0*yPixel*radius)) * 0.0540540541;
    sum += layer.sample(float2(offset.x + 4.0*xPixel*radius, offset.y + 4.0*yPixel*radius)) * 0.0162162162;
    
    return sum;
}

float normpdf(float x, float sigma) {
    return 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;
}

// https://www.shadertoy.com/view/XdfGDH
[[ stitchable ]] half4 gaussianBlur_2(float2 pos, SwiftUI::Layer layer, float2 size, float blur) {
    const int mSize = 11;
    const int kSize = (mSize-1)/2;
    float k[mSize];
    half3 final_colour = half3(0.0);
    
    //create the 1-D kernel
    float sigma = 3.0;
    float Z = 0.0;
    for (int j = 0; j <= kSize; ++j) {
        k[kSize+j] = k[kSize-j] = normpdf(float(j), sigma);
    }
    
    //get the normalization factor (as the gaussian has been clamped)
    for (int j = 0; j < mSize; ++j) {
        Z += k[j];
    }

    //read out the texels
    for (int i=-kSize; i <= kSize; ++i) {
        for (int j=-kSize; j <= kSize; ++j) {
            // * (1 - pos.y/size.y)
            // float2(float(i),float(j))
            float2 factor = float2(float(i),float(j));
            final_colour += k[kSize+j]*k[kSize+i]*layer.sample(pos + factor).rgb;
        
        }
    }
    
    half4 fragColor = half4(final_colour/(Z*Z), 1.0);
    return fragColor;
}

float SCurve (float x) {
    x = x * 2.0 - 1.0;
    return -x * abs(x) * 0.5 + x + 0.5;
}

// https://www.shadertoy.com/view/Mtl3Rj
[[ stitchable ]] half4 gaussianBlur_3(float2 pos, SwiftUI::Layer layer, float2 size, float radius) {
    float2 uv = pos/size;
    half4 A = half4(0.0);
    half4 C = half4(0.0);

    float width = 1.0 / uv.x;

    float divisor = 0.0;
    float weight = 0.0;
    
    float radiusMultiplier = 1.0 / radius;
    
    for (float x = -radius; x <= radius; x++) {
        A = layer.sample(pos + float2(x * width, 0.0));
        
        weight = SCurve(1.0 - (abs(x) * radiusMultiplier));
        
        C += A * weight;
        
        divisor += weight;
    }

    return half4(C.r / divisor, C.g / divisor, C.b / divisor, 1.0);
}

// https://www.shadertoy.com/view/Mtl3Rj
[[ stitchable ]] half4 gaussianBlur_3_2(float2 pos, SwiftUI::Layer layer, float2 size, float radius) {
    float2 uv = pos/size;
    half4 A = half4(0.0);
    half4 C = half4(0.0);

    float height = 1.0 / uv.y;

    float divisor = 0.0;
    float weight = 0.0;
    
    float radiusMultiplier = 1.0 / radius;
    
    for (float x = -radius; x <= radius; x++) {
        A = layer.sample(pos + float2(0.0, x * height));
        
        weight = SCurve(1.0 - (abs(x) * radiusMultiplier));
        
        C += A * height;
        
        divisor += height;
    }

    return half4(C.r / divisor, C.g / divisor, C.b / divisor, 1.0);
}

// https://www.shadertoy.com/view/ltBXRh
[[ stitchable ]] half4 gaussianBlur_4(float2 pos, SwiftUI::Layer layer, float2 size, float radius) {
    const int mSize = 25;
    const int kSize = (mSize-1)/2;
    const float sigma = 7.0;
    float k[mSize];
    
    half3 res = half3(0.0);
    float Z = 0.0;
    for (int j = 0; j <= kSize; ++j) {
        k[kSize+j] = k[kSize-j] = normpdf(float(j), sigma);
    }

    for (int j = 0; j < mSize; ++j) {
        Z += k[j];
    }

    for (int i=-kSize; i <= kSize; ++i) {
        for (int j=-kSize; j <= kSize; ++j) {
            //
            // adj for gradient blur, this is linear for top to bottom
            float adj = (1 - pos.y/size.y);
            float2 factor;
            factor = float2(float(i),float(j)) * adj;
            res += k[kSize+j]*k[kSize+i]*layer.sample(pos+factor).rgb;
        }
    }
    
    return half4(res / (Z * Z), 1.0);
}
