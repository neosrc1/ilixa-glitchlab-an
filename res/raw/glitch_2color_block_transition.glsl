precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include random
#include smoothrandom
#include locuswithcolor_nodep

uniform float u_Intensity;
uniform float u_Dampening;
uniform float u_Seed;
uniform float u_Variability;
uniform vec4 u_Color1;
uniform vec4 u_Color2;

vec4 offset(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    float scaleX = length(vec2(u_ModelTransform[0][0], u_ModelTransform[1][0]));

    vec2 rnd1 = rand2relSeeded(floor(u.yy), u_Seed);
    float xOffset = floor(15.0 * rnd1.x + 0.5);

    vec4 col = texture2D(u_Tex0, proj0(pos));
    float dx = floor(xOffset-u.x);
    vec2 rnd2 = rand2relSeeded(vec2(dx, floor(u.y)), u_Seed);

    if (dx + rnd2.y * u_Variability*4.0/abs(dx)<=0.0) return col;

    float kx = clamp(0.0, 1.0, 1.0-dx/scaleX);
    float scanIntensity = 0.3;
    float scanK = (1.0-scanIntensity + scanIntensity*cos(M_PI*fract(u.x)*8.0));
    vec4 overCol = mix(u_Color1, u_Color2, kx) * vec4(scanK, scanK, scanK, 1.0);

    float alpha = clamp(0.0, 1.0, 1.0-(1.0-kx)*u_Dampening*0.01);
    float intensity = getMaskedParameter(u_Intensity, outPos)*0.01 * alpha;
    vec4 outCol = mix(col, overCol, intensity);

    float locus = getLocus(pos, col, outCol);
    return mix(col, outCol, locus);
}

#include mainWithOutPos(offset)
