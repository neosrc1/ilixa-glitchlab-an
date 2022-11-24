precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include random
#include locuswithcolor_nodep

uniform float u_Thickness;
uniform float u_Mode;
uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform float u_Glow;
uniform float u_Seed;

vec4 spilloverChannels(vec4 c) {
    float overflow = (max(c.r-1.0, 0.0) + max(c.g-1.0, 0.0) + max(c.b-1.0, 0.0)) / 3.0;
    c.r += overflow;
    c.g += overflow;
    c.b += overflow;
    return c;
}

float sdBox(vec2 p, vec2 a) {
    vec2 d = abs(p)-a;
    return length(max(d, 0.0)) + min(max(d.x, d.y),0.0);
}

//float sdBox(vec2 p, vec2 a, vec2 b) {
//    vec2 d = -(a+b)/2.0;
//    return sdBox(p-d, abs(b-d));
//}

//float response(float d, float glow) {
//    if (d<=0.0) {
//        if (glow<20.0) return 1.0;
//        else return 1.0+(glow-20.0)*0.04;
//    }
//    else return min(1.0, glow*0.001/d);
//}

float response(float d, float glow) {
    float base = (glow<20.0) ? 1.0 : 1.0+(glow-20.0)*0.04;
    return base * (d<=0.0 ? 1.0 : min(1.0, glow*0.0001/d)) * smoothstep(2.0, 1.2, d);
}

vec4 barcode(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec2 rnd = rand2relSeeded(vec2(10.0, 10.0), u_Seed);
    vec2 rnd2 = rand2relSeeded(vec2(11.0, -5.5), u_Seed);
    float code1 = floor((rnd2.x+0.5)*256.0 + (rnd.x+0.5)*65536.0);
    float code2 = floor((rnd2.y+0.5)*256.0 + (rnd.y+0.5)*65536.0);

    float k = 0.0;
    float N = 26.0;
    float unit = 2.0/(3.0*N);
    float code = code1;
    for(float i=0.0; i<N; ++i) {
        float width = fmod(code, 2.0)+1.0;
        code = floor(code/2.0);
        if (code==0.0) code = code2;
        float d = sdBox(u-vec2((i/(N-1.0)-0.5)*2.0, 0.0), vec2(width*unit*0.5, 0.5));
        k += response(d, u_Glow);
    }

    vec4 bkgCol = texture2D(u_Tex0, proj0(pos));
    vec4 targetCol = spilloverChannels(vec4(mix(bkgCol.rgb, u_Color1.rgb, u_Color1.a)*max(1.0, k), bkgCol.a));
    vec4 outCol = mix(bkgCol, targetCol, min(1.0, k));

    float locus = getLocus(pos, bkgCol, outCol);
    return mix(bkgCol, outCol, locus);
}

#include mainWithOutPos(barcode)
