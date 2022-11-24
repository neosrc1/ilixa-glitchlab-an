precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include color

uniform float u_Intensity;
uniform float u_Saturation;
uniform float u_Tolerance;
uniform vec4 u_Color;

vec4 emphasize(vec2 pos) {
    vec4 inc = texture2D(u_Tex0, proj0(pos));

    vec4 inHsl = RGBtoHSL(inc);
    vec4 empHsl = RGBtoHSL(u_Color);
    vec2 delta = vec2((inHsl.x-empHsl.x)/180.0, inHsl.y-empHsl.y);
    if (delta.x>1.0) delta.x = 2.0-delta.x;
    float dist = length(delta);

    float tolerance = u_Tolerance*0.01;
    if (dist >= tolerance) return inc;

    vec4 rgb = colorize(inc, u_Color, u_Saturation*0.01);

    float intensity = getMaskedParameter(u_Intensity, pos) * (1.0-dist/tolerance);
    return mix(inc, rgb, intensity*0.01);
//    float intensity = getMaskedParameter(u_Intensity, pos);
//    return mix(inc, mix(inc, rgb, intensity*0.01), dist/tolerance);
}

#include mainPerPixel(emphasize)
