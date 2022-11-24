precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include tex(1)

uniform float u_Vignetting;
uniform float u_Hardness;
uniform float u_K1;
uniform float u_K2;

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
    float intensity = getMaskedParameter(u_Vignetting*0.01, outPos);
    float k = (1.0-insideFadingCircle(pos, u_ModelTransform)*intensity);
    float k2 = u_K2*k;
    float k1 = u_K1 + (u_K2-k2);
    vec4 outc = k1*inc1 + k2*inc2;
    return vec4(outc.rgb, inc1.a);

////    return clamp(u_K1*inc1 + u_K2*inc2, 0.0, 1.0);
//    return clamp(vec4(0.5,0.5,0.5,1.0) , 0.0, 1.0);
}

#include mainWithOutPos(blend)
