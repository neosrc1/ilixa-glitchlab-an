precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform float u_PosterizeCount;
uniform float u_Count;
uniform float u_Mode;

float pattern(int w, int h, float bits, vec2 u) {
    float index = fmod(u.x, float(w)) + float(w)*fmod(u.y, float(h));
    return fmod(floor(bits/pow(2.0, index)), 2.0);
}

float pattern2(int w, int h, float bits, vec2 u) {
    float index = fmod(u.x, float(w)) + float(w)*fmod(u.y, float(h));
    return fmod(bits/pow(2.0, index), 2.0);
}

vec4 checkerboard(vec2 pos, vec2 outPos) {
    vec2 u = floor((u_ModelTransform * vec3(pos, 1.0)).xy);
    float k;
    if (u_Mode==0.0) k = pattern(2, 2, 6.0, u);
    else if (u_Mode==1.0) k = pattern(3, 3, 84.0, u);
    else if (u_Mode==2.0) k = pattern(4, 4, 1285.0, u);
    else if (u_Mode==3.0) k = pattern(3, 3, 27.0, u);
    else if (u_Mode==4.0) k = pattern(4, 4, 41380.0, u);
    else {
        vec2 rnd = rand2rel(vec2(u_Mode, u_Mode));
        vec2 rnd2 = rand2rel(vec2(u_Mode, u_Mode));
        vec2 rnd3 = rand2rel(vec2(u_Mode, u_Mode));
        vec2 rnd4 = rand2rel(vec2(u_Mode, u_Mode));
        int w = int(fmod(rnd.x, 4.0)+2.0);
        int h = int(fmod(rnd.y, 4.0)+2.0);

        float bits = fmod(rnd.x*8.0, 8.0) + fmod(rnd.y*8.0, 8.0)*8.0
                   + fmod(rnd2.x*8.0, 8.0)*64.0 + fmod(rnd2.y*8.0, 8.0)*512.0
                   + fmod(rnd3.x*8.0, 8.0)*4096.0 + fmod(rnd3.y*8.0, 8.0)*32768.0
                   + fmod(rnd4.x*8.0, 8.0)*262144.0 + fmod(rnd4.y*8.0, 8.0)*2097152.0;
        k = fmod(u_Mode, 2.0)==0.0 ? pattern(w, h, floor(bits), u) : pattern2(w, h, bits, u);
    }
    return mix(u_Color1, u_Color2, k);
}

vec4 checkerboard0(vec2 pos, vec2 outPos) {
    vec2 u = floor((u_ModelTransform * vec3(pos, 1.0)).xy);
    return fmod(u.x+u.y, u_Count)==0.0 ? u_Color1 : u_Color2;
}

#include mainWithOutPos(checkerboard)
