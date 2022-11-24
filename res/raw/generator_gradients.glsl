precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include rand3

uniform vec4 u_Color1;
uniform float u_PosterizeCount;
uniform float u_ColorVariability;
uniform float u_Seed;

vec4 gradients(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    if (u_PosterizeCount<256.0) {
        u.y = floor(u.y*u_PosterizeCount+0.5) / u_PosterizeCount;
    }
    vec3 rndCol = interpolatedRand3Seeded(vec2(0.0, u.y), u_Seed)*u_ColorVariability*0.01 + u_Color1.rgb;
    return vec4(rndCol, 1.0);
    //return abs(u.y-floor(u.y))<0.05 ? vec4(vec3(1.0,1.0,1.0)-rndCol, 1.0): vec4(rndCol, 1.0);
}

#include mainWithOutPos(gradients)
