precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include color

uniform float u_Intensity;
uniform float u_Saturation;

float hillDistance(vec2 pos) {
    vec2 origin = (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy;
    vec2 one = (u_ModelTransform*vec3(1.0, 0.0, 1.0)).xy;
    vec2 dir = one-origin;
    float len = length(dir);
    return dot((pos-origin)/len, dir/len);
}

vec4 addHue(vec4 sourceColor, float hue, float saturation) {
    vec4 hslSource = RGBtoHSL(sourceColor);

    hslSource.r += hue;
    hslSource.g = 1.0*saturation + hslSource.g*(1.0-saturation);

    return HSLtoRGB(hslSource);
}

vec4 hills(vec2 pos) {
    vec4 inc = texture2D(u_Tex0, proj0(pos));
    float s = u_Saturation*0.01;

    float k = hillDistance(pos);
    float hue = k*360.0;
    vec4 rgb = addHue(inc, hue, s);

    float intensity = getMaskedParameter(u_Intensity, pos);
    return mix(inc, rgb, intensity*0.01);
}

#include mainPerPixel(hills)
