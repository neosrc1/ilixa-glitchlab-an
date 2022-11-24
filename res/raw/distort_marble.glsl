precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include perspective
#include random

uniform int u_Count;
uniform float u_Intensity;

vec2 perlinDisplace(vec2 u, vec2 v, int count, float intensity) {
    float s = 1.0;
    float maxDisplacement = intensity; //pow(intensity*0.01f, 2);

    vec2 totalDisp;

    for(int i = 0; i<count; ++i) {
        vec2 disp = interpolatedRand2(v*s);
        totalDisp += maxDisplacement * (disp - vec2(0.5, 0.5))*2.0;

        maxDisplacement *= 0.5;
        s *= 2.2;
    }

    return u + totalDisp;
}

vec4 marble(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float intensity = getMaskedParameter(u_Intensity, outPos);
    if (intensity != 0.0) {
        pos = perlinDisplace(pos, t, u_Count, intensity*0.02);
    }

    return texture2D(u_Tex0, proj0(pos));

}

#include mainWithOutPos(marble)
