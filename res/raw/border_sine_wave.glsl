precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Thickness;
uniform vec4 u_Color;
uniform float u_Seed;
uniform float u_Variability;
uniform float u_Size;


vec2 interpolatedRand2Seeded(vec2 v, float seed) {
    float sfractY = smoothstep(0.0, 1.0, fract(v.y));
    return mix(
        mix(rand2relSeeded(floor(v), seed), rand2relSeeded(vec2(floor(v.x), ceil(v.y)), seed), sfractY),
        mix(rand2relSeeded(vec2(ceil(v.x), floor(v.y)), seed), rand2relSeeded(ceil(v), seed), sfractY),
        smoothstep(0.0, 1.0, fract(v.x)) );
}

float lenP(vec2 u, float k) {
	return pow(pow(u.x, k) + pow(u.y, k), 1.0/k);
}

float sinewaves(vec2 coord, float angle, float r, float baseAmp, float varAmp, float baseThickness, float varThickness) {
    float scale = u_Size + 15.0;
	vec2 base = floor(vec2(r*scale, r*scale));
    float seed = u_Seed;
    //int N = 8;
    //int(ceil(k*0.01+baseRadius*varRadius));
    //for(int j = -N; j <= N; ++j) {
    //    vec2 center = vec2(0.0, float(j)) + base;
    float value = 0.0;
    for(int j = -2; j <= int(scale)+2; ++j) {
        vec2 center = vec2(0.0, float(j));
        vec2 delta = rand2relSeeded(center, seed);
        center += u_Variability * vec2(6.0, 2.0)/scale*delta;
        float amp = (varAmp*delta.x + 1.0)*baseAmp;
        float thickness = (varThickness*delta.y + 1.0)*baseThickness;
        float rr = center.y + amp*sin(center.x + angle*10.0);
        float d = abs(r*scale-rr)/(30.0*thickness);
        if (d<1.0) {
            float k = 0.8;
            if (d<k) {
            	return 1.0;
            }
            else {
                value = max(value, (1.0-d)/(1.0-k));//smoothstep(k, 1.0, d);
            }
        }
    }
    return value;
}


float borderDistanceRounded(vec2 coord, float radius, float thickness) {
    float ratio = u_outDim.x / u_outDim.y;
    float D = radius+thickness;
    float x1 = (-ratio+D-coord.x)/D;
    float x2 = (coord.x-(ratio-D))/D;
    float y1 = (-1.0+D-coord.y)/D;
    float y2 = (coord.y-(1.0-D))/D;
    float X = max(x1, x2);
    float Y = max(y1, y2);
    if (X>0.0 && Y>0.0) {
        return length(vec2(X, Y)) - radius/(radius+thickness);
    }
    else {
        return max(X, Y) - radius/(radius+thickness);
    }
}

vec4 border(vec2 pos, vec2 outPos) {
    float ratio = u_outDim.x / u_outDim.y;

    float B = borderDistanceRounded(outPos, u_Thickness*0.01, u_Thickness*0.01) + u_Variability*0.01 * 0.08*interpolatedRand2Seeded(pos*10.0, u_Seed).x;
    if (B<=0.0) return texture2D(u_Tex0, proj0(pos));

    float angle = getVecAngle(outPos);
    float k = 1.0 - sinewaves(pos, angle, B, 2.0, 1.0, 0.1*(B<0.0?0.0:pow(B, 0.7)), 0.5);
//    float k = 1.0 - sinewaves(pos, angle, pos.x, 2.0, 1.0, 0.5, 0.5);

    if (k==0.0) return u_Color;
    return mix(u_Color, texture2D(u_Tex0, proj0(pos)), k);
}

#include mainWithOutPos(border)
