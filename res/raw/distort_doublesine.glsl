precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include smoothrandom

uniform float u_Count;
uniform float u_Intensity;
uniform mat3 u_InverseModelTransform;

vec4 doublesine(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;



    float intensity = getMaskedParameter(u_Intensity, outPos);

    u += intensity * vec2(sin(u.x), sin(u.y));

    vec2 coord = (u_ModelTransform * vec3(u.x, u.y, 1.0)).xy;
    return texture2D(u_Tex0, proj0(coord));

}

#include mainWithOutPos(doublesine)
