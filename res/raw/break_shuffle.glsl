precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include perspective
#include random

uniform float u_Intensity;
uniform float u_Dampening;
uniform float u_Phase;
uniform mat3 u_InverseModelTransform;

vec4 shuffle(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    vec2 indices = floor(u);
    vec2 d = u-indices;

    if (u_Phase != 0.0) {
        float cosPhase = cos(u_Phase);
        float sinPhase = sin(u_Phase);
        vec2 ri = vec2(floor(indices.x*cosPhase - indices.y*sinPhase + 0.5),
                           floor(indices.x*sinPhase + indices.y*cosPhase + 0.5));
        indices = ri;
    }

    if (u_Intensity != 0.0) {
        vec2 rnd = rand2(indices)*20.0-10.0;
        float probability = fract(rnd).x;
        if (u_Intensity*0.01 > probability) {
            vec2 delta = ceil(rnd); //vec2(ceil(rnd.x), round(rnd.y));
            indices += delta;
        }
    }

    u = indices + d;

    vec2 coord = (u_ModelTransform * vec3(u, 1.0)).xy;

    return texture2D(u_Tex0, proj0(coord));

}

#include mainWithOutPosAndPerspectiveFit(shuffle)
