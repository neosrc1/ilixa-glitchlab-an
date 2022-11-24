precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math

uniform float u_Intensity;
uniform float u_Hardness;
uniform vec4 u_Color;

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
    return dampenSLinear(1.0-distance, u_Hardness*0.01);
}

vec4 vignette(vec2 pos, vec2 outPos) {
    vec4 inc = texture2D(u_Tex0, proj0(pos));
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);
    float k = (1.0-insideFadingCircle(pos, u_ModelTransform)) * intensity;
//    return vec4(intensity, k, length((u_ModelTransform*vec3(pos, 1.0)).xy), 1.0);//mix(inc, u_Color, k);
    return mix(inc, u_Color, k);
}

#include mainWithOutPos(vignette)
