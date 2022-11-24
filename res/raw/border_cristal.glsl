precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Left;
uniform float u_Right;
uniform float u_Top;
uniform float u_Bottom;
uniform vec4 u_Color;
uniform float u_Seed;

float voronoiBoundary(vec2 coord, float k, float thickness) {
	vec2 base = floor(coord);
    float minD = 1000.0;
    float minD2 = 10000.0;
    float seed = u_Seed;
    int N = int(ceil(k*0.01))+1;
    for(int j = -N; j <= N; ++j) {
        for(int i = -N; i <= N; ++i) {
            vec2 center = vec2(float(i), float(j)) + base;
            vec2 delta = rand2relSeeded(center, seed);
            center += vec2(0.5, 0.5) + delta*k*0.02;
            vec2 v = coord - center;
            float d = length(v);
            if (d < minD) {
                minD2 = minD;
                minD = d;
            }
            else if (d < minD2) {
                minD2 = d;
            }
        }
    }

    return (minD2-minD)<thickness ? 1.0 : 0.0;
}

vec2 interpolatedRand2Seeded(vec2 v, float seed) {
    float fractY = fract(v.y);
    return mix(
        mix(rand2relSeeded(floor(v), seed), rand2relSeeded(vec2(floor(v.x), ceil(v.y)), seed), fractY),
        mix(rand2relSeeded(vec2(ceil(v.x), floor(v.y)), seed), rand2relSeeded(ceil(v), seed), fractY),
        fract(v.x) );
}


float borderDistance(vec2 coord, float M) {
    float ratio = u_outDim.x / u_outDim.y;
	float X = max(u_Left<=0.0 ? 0.0 : max((-ratio+u_Left-coord.x)/u_Left, u_Right<=0.0 ? 0.0 : (coord.x-(ratio-u_Right))/u_Right),
                  max(u_Top<=0.0 ? 0.0 : (-1.0+u_Top-coord.y)/u_Top, u_Bottom<=0.0 ? 0.0 : (coord.y-(1.0-u_Bottom))/u_Bottom) );
    return X;
}

vec4 border(vec2 pos, vec2 outPos) {
    float ratio = u_outDim.x / u_outDim.y;

    if (u_Left==0.0 && u_Right==0.0 && u_Top==0.0 && u_Bottom==0.0) return texture2D(u_Tex0, proj0(pos));

    float B = borderDistance(outPos, 0.1) + 0.25*interpolatedRand2Seeded(pos*10.0, u_Seed).x;
    if (B<=0.0) return texture2D(u_Tex0, proj0(pos));

    float k = 1.0-voronoiBoundary((u_ModelTransform * vec3(pos, 1.0)).xy, 200.0, 0.25*B);

    if (k==0.0) return u_Color;
    return mix(u_Color, texture2D(u_Tex0, proj0(pos)), k);
}

#include mainWithOutPos(border)
