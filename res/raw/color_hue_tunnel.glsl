precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include color

uniform float u_Intensity;
uniform float u_Saturation;
uniform float u_HueOffset;

float circleDistance(vec2 pos, mat3 transform) {
    float distance = length((transform*vec3(pos, 1.0)).xy);
    return distance;
}

vec4 addHue(vec4 sourceColor, float hue, float saturation) {
    vec4 hslSource = RGBtoHSL(sourceColor);

    hslSource.r += hue;
    hslSource.g = 1.0*saturation + hslSource.g*(1.0-saturation);

    return HSLtoRGB(hslSource);
}

vec4 tunnel(vec2 pos) {
    vec4 inc = texture2D(u_Tex0, proj0(pos));
    float s = u_Saturation*0.01;

    float k = circleDistance(pos, u_ModelTransform);
    float hue = k*360.0 + u_HueOffset;
    vec4 rgb = addHue(inc, hue, s);

    float intensity = getMaskedParameter(u_Intensity, pos);
    return mix(inc, rgb, intensity*0.01);
}

#include mainPerPixel(tunnel)
