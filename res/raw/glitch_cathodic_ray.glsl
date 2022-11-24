precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Balance;

vec4 ray0(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float k = fmod(u.y+2.0, 2.0)*0.5;

    vec4 color = texture2D(u_Tex0, proj0(pos));
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);
    float base = pow(10.0, intensity*20.0);
    k = 0.5*pow(base, k)/(base/10.0) + 0.5*(pow(10000.0, k)/1000.0);
    //    k = max(pow(base, k)/(base/10.0), (pow(1000.0, k)/100.0));
    vec4 outCol = color*vec4(k, k, k, 1.0);
    return mix(color, outCol, clamp(0.0, 1.0, intensity*3.0));
}

vec4 ray(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float k = fmod(u.y+2.0, 2.0)*0.5;

    vec4 color = texture2D(u_Tex0, proj0(pos));
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);
    float base = pow(10.0, intensity*20.0);
    k = u_Balance*0.01 + 0.5*pow(base, k)/(base/10.0);

    vec3 outCol = color.rgb*vec3(k, k, k);
    return vec4(clamp(0.0, 1.0, outCol.r), clamp(0.0, 1.0, outCol.g),clamp(0.0, 1.0, outCol.b), color.a);
}

#include mainWithOutPos(ray)
