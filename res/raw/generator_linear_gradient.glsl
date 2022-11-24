precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform float u_PosterizeCount;



vec4 linearGradient(vec2 pos, vec2 outPos) {

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float k = clamp((u.x+1.0)/2.0, 0.0, 1.0);
    if (u_PosterizeCount<256.0) {
        k = min(floor(k*u_PosterizeCount) / (u_PosterizeCount-1.0), 1.0);
    }

    return mix(u_Color1, u_Color2, k);

}

#include mainWithOutPos(linearGradient)
