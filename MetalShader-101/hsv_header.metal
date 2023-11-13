#include <metal_stdlib>
using namespace metal;


#ifndef HSV
#define HSV

float3 rgb2hsv(float r, float g, float b);
float3 hsv2rgb(float h, float s, float v);

#endif
