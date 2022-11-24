precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include smoothrandom

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Dampening;
uniform float u_Perturbation;
uniform float u_Seed;
uniform float u_Power;

uniform mat3 u_InverseModelTransform;

vec4 hyperbolic(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(0.0, 0.0, 1.0)).xy;
    float radius = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    float len = length(pos-u);
    vec2 dir = normalize(pos-u);
    float inversedLen = radius / len;
    vec2 v = u + inversedLen*dir;
    float intensity = getMaskedParameter(u_Intensity, outPos);
    if (intensity!=-100.0) {
        float k = len<radius ? pow(len/radius, 2.0*pow(1.04, intensity)) : 1.0;
        if (intensity<0.0) k = mix(k, 1.0, -intensity/100.0); // transition towards full v at intensity = -100.0
        v = mix(pos, v, k);
    }
    return texture2D(u_Tex0, proj0(v));
}

#include mainWithOutPos(hyperbolic)
