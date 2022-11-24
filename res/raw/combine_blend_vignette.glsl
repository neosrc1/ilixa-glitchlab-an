precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include tex(1)

uniform float u_Vignetting;
uniform float u_Intensity;
uniform float u_Hardness;

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

vec4 blend(vec2 pos, vec2 outPos) {
    vec4 inc1 = texture2D(u_Tex0, proj0(pos));
    vec4 inc2 = texture2D(u_Tex1, proj1(pos));
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);
    float inside = insideFadingCircle(pos, u_ModelTransform);
    float k = intensity * (1.0 - inside*u_Vignetting*0.01);
    //return vec4(inside, mix(inc1, inc2, k).gba);
    return mix(inc1, inc2, k);
}

#include mainWithOutPos(blend)
