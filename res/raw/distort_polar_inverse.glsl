precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform float u_Ratio;
uniform mat3 u_InverseModelTransform;
uniform float u_Phase;

vec4 polarInv(vec2 pos, vec2 outPos) {
    //vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;
    float ratio = u_Tex0Dim.x / u_Tex0Dim.y;
    float angle = pos.x * M_PI + u_Phase + M_PI;
    float len = (1.0-pos.y)*0.72;

    vec2 u = len * vec2(cos(angle), sin(angle));
    vec2 v = (u_ModelTransform * vec3(u, 1.0)).xy;

    return texture2D(u_Tex0, proj0(v));
}

#include mainWithOutPos(polarInv)
