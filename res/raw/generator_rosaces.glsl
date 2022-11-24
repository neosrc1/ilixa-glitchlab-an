precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include perspective

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform int u_Count; // levels
uniform float u_Regularity;
uniform float u_Distribution;
uniform float u_Seed;

float inCircle(vec2 c, float r, vec2 p) {
    return length(c-p)<r ? 1.0 : 0.0;
}

float inCircle2(float a, float d, float r, vec2 p) {
    return inCircle(d*vec2(-sin(a), cos(a)), r, p);

}

float inRosace(float r1, float r2, int N, vec2 p) {
    float di = length(p);
    if (di<r1 || di>r2) return 0.0;

    float r = (r2-r1)/2.0;
    float d = r2-r;
    float inside = 0.0;
    for(int i=0; i<N; ++i) {
        float a = M_2PI*float(i)/float(N);
        inside += inCircle2(a, d, r, p);
    }
    return inside;
}

vec2 rnd2(vec2 u) {
    return fract(vec2(sin(u.x*10013.13+454.0)*100.0, cos(u.y*3123.13+787.0)*100.0));
}

float makeDivisible(float a, float b) {
    if (a>b) {
        return b*floor(a/b+0.5);
    }
    else {
        return a*floor(b/a+0.5);
    }
}

vec4 rosace(vec2 pos, vec2 outPos) {
    pos = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;

    vec2 gridPos = (pos+vec2(1.0, 1.0))/2.0;
    vec2 gridIndex = floor(gridPos);
    pos = (fract(gridPos)-vec2(0.5, 0.5))*2.0;
    vec2 rnd = rand2relSeeded(gridIndex, u_Seed)+vec2(0.5, 0.5);

    int levels = int(1.0 + floor(rnd.x*3.0));

    float N = 1.0;
    float inside = 0.0;
    float r1 = 0.75;
    float r2;

    if (gridIndex.x==0.0 && gridIndex.y==0.0 && u_Seed==0.0) {
        inside += inRosace(0.0, 0.25, 24, pos);
        inside += inRosace(0.25, 0.35, 12, pos);
        inside += inRosace(0.35, 0.75, 60, pos);
    }
    else for(int j=0; j<levels; ++j) {
        rnd = rand2relSeeded(rnd, u_Seed)+vec2(0.5, 0.5);
        r2 = r1;
        r1 = r1 * rnd.x;
        if (r1/r2>0.9) r1 = r2*0.9;
        if (r1<0.05) r1 = 0.0;
        N = makeDivisible(N, floor(rnd.y*rnd.y*60.0)+2.0);
        inside += inRosace(r1, r2, int(N), pos);
    }

    float k = fmod(inside, 2.0)<1.0 ? 1.0 : 0.0;

    return mix(u_Color2, u_Color1, k);

}

#include mainWithOutPos(rosace)
