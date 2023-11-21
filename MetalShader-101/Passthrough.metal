#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 passthrough(float2 position, half4 color) {
    return color;
}

[[ stitchable ]] half4 recolor(float2 position, half4 color) {
    return half4(0, position.x/position.y, 0 , color.a);
}

[[ stitchable ]] half4 invertAlpha(float2 position, half4 color) {
    return half4(color.r, color.g, color.b, 1 - color.a);
}

[[ stitchable ]] half4 rainbow(float2 pos, half4 color, float t) {
    float angle = atan2(pos.y, pos.x) + t;
    return half4(
                 sin(angle),
                 sin(angle + 2),
                 sin(angle + 4),
                 color.a
                 );
}

[[ stitchable ]] float2 wave2(float2 pos, float t) {
    pos.x += sin(t * 5 + pos.x / 20) * 5;
    pos.y += sin(t * 5 + pos.y / 20) * 5;
    return pos;
}

[[ stitchable ]] float2 wave3(float2 pos, float t, float2 s) {
    float2 distance = pos / s;
    pos.y += sin(t * 5 + pos.y / 20) * distance.x * 10;
    return pos;
    
}

// layer Effect

[[ stitchable ]] half4 loupe(float2 pos, SwiftUI::Layer l, float2 size, float2 touch) {
    float maxDistance = 0.05;
    float2 uv = pos/size;
    float2 center = touch/size;
    float2 delta = uv - center;
    float aspectRatio = size.x / size.y;
    
    float distance = (delta.x * delta.x) + (delta.y * delta.y) / aspectRatio ;
    
    float totalZoom = 1;
    
    if (distance < maxDistance) {
        totalZoom /= 2;
        totalZoom += distance * 10;
    }
    float2 newPos = delta * totalZoom + center;
    
    return l.sample(newPos * size);
}
