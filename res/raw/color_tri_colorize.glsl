precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include color

uniform float u_Intensity;
uniform float u_Saturation;
uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform vec4 u_Color3;
uniform mat3 u_ModelTransform1;
uniform mat3 u_ModelTransform2;
uniform mat3 u_ModelTransform3;

float dampenSLinear(float x, float maxLen) {
    if (x>=1.0-maxLen) return 1.0;
    x = x/(1.0-maxLen);
    if (x<0.33333333) {
        return x*x*9.0*0.25;
    }
    else if (x<=0.666666667) {
        return (x*1.5)-0.25;
    }
    else {
        x = 1.0-x;
        x = x*x*9.0*0.25;
        return 1.0-x;
    }
}

float insideFadingCircle(vec2 pos, mat3 transform) {
    float distance = length((transform*vec3(pos, 1.0)).xy);
    if (distance >= 1.0) return 0.0;
    return dampenSLinear(1.0-distance, 0.6);
}

vec4 triColorize(vec2 pos) {
    vec4 inc = texture2D(u_Tex0, proj0(pos));
    float s = u_Saturation*0.01;

    vec4 rgb1 = colorize(inc, u_Color1, s);
    float k1 = insideFadingCircle(pos, u_ModelTransform1);

    vec4 rgb2 = colorize(inc, u_Color2, s);
    float k2 = insideFadingCircle(pos, u_ModelTransform2);

    vec4 rgb3 = colorize(inc, u_Color3, s);
    float k3 = insideFadingCircle(pos, u_ModelTransform3);

    float ki = max(0.0, 1.0-k1-k2-k3);
    vec4 rgb = (ki*inc + k1*rgb1 + k2*rgb2 + k3*rgb3) / (ki + k1 + k2 + k3);

    float intensity = getMaskedParameter(u_Intensity, pos);
    return mix(inc, rgb, intensity*0.01);
}

#include mainPerPixel(triColorize)
