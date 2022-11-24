precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform vec4 u_Color3;
uniform vec4 u_Color4;
uniform float u_PosterizeCount;



vec4 corners(vec2 pos, vec2 outPos) {

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float k1 = length(u-vec2(-1.0, -1.0));
    if (k1==0.0) return u_Color1;

    float k2 = length(u-vec2(-1.0, 1.0));
    if (k2==0.0) return u_Color2;

    float k3 = length(u-vec2(1.0, -1.0));
    if (k3==0.0) return u_Color3;

    float k4 = length(u-vec2(1.0, 1.0));
    if (k4==0.0) return u_Color4;


    if (u_PosterizeCount<256.0) {
        k1 = min(floor(k1*u_PosterizeCount) / (u_PosterizeCount-1.0), 1.0);
        k2 = min(floor(k2*u_PosterizeCount) / (u_PosterizeCount-1.0), 1.0);
        k3 = min(floor(k3*u_PosterizeCount) / (u_PosterizeCount-1.0), 1.0);
        k4 = min(floor(k4*u_PosterizeCount) / (u_PosterizeCount-1.0), 1.0);
    }

    float inv1 = 1.0/k1;
    float inv2 = 1.0/k2;
    float inv3 = 1.0/k3;
    float inv4 = 1.0/k4;
    float tot = inv1 + inv2 + inv3 + inv4;
    inv1 /= tot;
    inv2 /= tot;
    inv3 /= tot;
    inv4 /= tot;

    return u_Color1*inv1 + u_Color2*inv2 + u_Color3*inv3 + u_Color4*inv4;

}

#include mainWithOutPos(corners)
