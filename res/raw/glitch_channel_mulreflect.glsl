precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include locuswithcolor_nodep

uniform float u_Hue;
uniform float u_Saturation;
uniform float u_Brightness;
uniform float u_Mode;
uniform float u_Red;
uniform float u_Blue;
uniform float u_Green;
uniform float u_Intensity;

float mulReflect(float x, float k) {
    float range = 1.003921568627451;
    float xx = fmod(x*k, range*2.0);
    return clamp(0.0, 1.0, xx>range ? 2.0*range-xx : xx);
}

vec4 offset(vec2 pos) {
    float mode = floor(u_Mode);
    float rMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float gMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float bMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float hMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float sMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float lMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float range = 1.003921568627451*2.0;
    vec4 col = texture2D(u_Tex0, proj0(pos));
    vec4 rgb = col;
    rgb.r = mulReflect(rgb.r, rMul*u_Red*0.1);
    rgb.g = mulReflect(rgb.g, gMul*u_Green*0.1);
    rgb.b = mulReflect(rgb.b, bMul*u_Blue*0.1);
    vec4 hsl = RGBtoHSL(rgb);
    hsl.x = fmod(hsl.x*hMul*u_Hue*0.1, 360.0);
    hsl.y = mulReflect(hsl.y, hMul*u_Saturation*0.1);
    hsl.z = mulReflect(hsl.z, hMul*u_Brightness*0.1);
    vec4 outCol = HSLtoRGB(hsl);

    float intensity = getMaskedParameter(u_Intensity, pos) * 0.01;
    intensity *= getLocus(pos, col, outCol);
    return mix(col, outCol, intensity);
}

#include mainPerPixel(offset)
