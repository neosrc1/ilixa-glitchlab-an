precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform int u_Count;
uniform float u_Intensity;

//vec2 perlinDisplace(vec2 u, vec2 v, int count, float intensity) {
//    float s = 1.0;
//    float maxDisplacement = intensity; //pow(intensity*0.01f, 2);
//
//    vec2 totalDisp;
//
//    for(int i = 0; i<count; ++i) {
//        vec2 disp = interpolatedRand2(v*s);
//        totalDisp += maxDisplacement * (disp - vec2(0.5, 0.5))*2.0;
//
//        maxDisplacement *= 0.5;
//        s *= 2.2;
//    }
//
//    return u + totalDisp;
//}

float perlin(vec2 u, int count) {
    float s = 1.0;
        float k = 0.5;
        float total;
        vec3 uu = vec3(u, 1.0);

        mat3 pt = mat3(0.958851077208406, 1.7551651237807455, 0.0, -1.7551651237807455, 0.958851077208406, 0.0, 0.0, 0.0, 1.0);
        for(int i = 0; i<count; ++i) {
            vec2 color = interpolatedRand2(uu.xy);
            total += ((color.x+color.y)-1.0)*k;
            k *= 0.5;
            uu = pt*uu;
            //s *= 2.2;
        }

        return total;
}

vec4 grain(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float intensity = getMaskedParameter(u_Intensity, outPos);

    vec4 color = texture2D(u_Tex0, proj0(pos));
    if (intensity != 0.0) {
//        color.rgb = color.rgb * (1.0 + perlinDisplace(pos, t, u_Count, intensity*0.02).x);
        float lumNoise = perlin(t, u_Count);
        color.rgb = color.rgb * (1.0 + intensity*0.02*lumNoise);
    }

    return color;
}

#include mainWithOutPos(grain)
