precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform float u_PosterizeCount;
uniform float u_Hardness;



vec4 radialGradient(vec2 pos, vec2 outPos) {

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float len = length(u);
    float maxD = u_Hardness*0.01;

    float k;
    if (len <= maxD) {
        k = 0.0;
    }
    else if (maxD>=1.0) {
        k = 1.0;
    }
    else {
        k = clamp((len-maxD)/(1.0-maxD), 0.0, 1.0);
    }
    if (u_PosterizeCount<256.0) {
        k = min(floor(k*u_PosterizeCount) / (u_PosterizeCount-1.0), 1.0);
    }

    return mix(u_Color1, u_Color2, k);

}

#include mainWithOutPos(radialGradient)
