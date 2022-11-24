precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include random
#include locuswithcolor_nodep

uniform float u_Balance;
uniform float u_Regularity;
uniform float u_Seed;
uniform float u_Thickness;
uniform vec4 u_Color1;
uniform float u_Intensity;
uniform float u_Count;
uniform int u_Mode;

vec2 distort(vec2 pos, vec2 a, vec2 b, vec2 A, vec2 B, float intensity) {
    vec2 c = (a+b)/2.0;
    if (u_Mode==0) {
        vec2 k = (pos-a)/(b-a);
        vec2 p = A + (B-A)*vec2(smoothstep(0.0, 1.0, k.x), smoothstep(0.0, 1.0, k.y));
        return p;//os + (p-pos)*intensity*0.1;
    }
    else if (u_Mode<=1) {
        vec2 p = A + (B-A)*(pos-a)/(b-a);
        return p;//os + (p-pos)*intensity*0.1;
    }
    else {
        vec2 p = A + (b-A)*(pos-a)/(B-a);
        return pos + (p-pos)*intensity*0.1;
    }
}

vec4 dist(vec2 pos, vec2 outPos) {
    float intensity = u_LocusMode>=6 ? u_Intensity : u_Intensity * getLocus(pos, vec4(0.0, 0.0, 0.0, 0.0), vec4(0.0, 0.0, 0.0, 0.0));
    intensity = intensity*0.01;

    //vec2 bias = (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy;
    //float scale = 1.0/length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;

    float variability = 1.0-u_Regularity*0.01;

    float x = pos.x/ratio;
    vec2 Xref = vec2(-1.0, 1.0);
    vec2 Xtar = vec2(-1.0, 1.0);
    float subCount = 0.0;
    float level = 1.0;
    float maxLevel = floor(log2(u_Count))+1.0;
    while (subCount<u_Count && level<=maxLevel) {
        vec2 rnd = rand2relSeeded(Xref, u_Seed+122.1);
        float xSplit = mix(Xtar.x, Xtar.y, rnd.x*variability+0.5);
        float xRefSplit = mix(Xref.x, Xref.y, 0.5);
        if (x<xSplit) {
            Xref.y = xRefSplit;
            Xtar.y = xSplit;
            subCount *= 2.0;
        }
        else {
            Xref.x = xRefSplit;
            Xtar.x = xSplit;
            subCount = 2.0*subCount+1.0;
        }
        level *= 2.0;
    }

    float y = pos.y/ratio;
    vec2 Yref = vec2(-1.0, 1.0);
    vec2 Ytar = vec2(-1.0, 1.0);
    subCount = 0.0;
    level = 1.0;
    maxLevel = floor(log2(u_Count))+1.0;
    while (subCount<u_Count && level<=maxLevel) {
        vec2 rnd = rand2relSeeded(Yref, u_Seed+122.1);
        float ySplit = mix(Ytar.x, Ytar.y, rnd.y*variability+0.5);
        float yRefSplit = mix(Yref.x, Yref.y, 0.5);
        if (y<ySplit) {
            Yref.y = yRefSplit;
            Ytar.y = ySplit;
            subCount *= 2.0;
        }
        else {
            Yref.x = yRefSplit;
            Ytar.x = ySplit;
            subCount = 2.0*subCount+1.0;
        }
        level *= 2.0;
    }

    vec2 p = distort(pos/(ratio, 1.0), vec2(Xtar.x, Ytar.x), vec2(Xtar.y, Ytar.y), vec2(Xref.x, Yref.x), vec2(Xref.y, Yref.y), intensity);
    p.x *= ratio;

    vec4 col = texture2D(u_Tex0, proj0(pos));

    vec4 outCol = texture2D(u_Tex0, proj0(p));

    if (u_LocusMode>=6) {
        vec4 col = texture2D(u_Tex0, proj0(pos));
        float locIntensity = getLocus(pos, col, outCol);
        return mix(col, outCol, locIntensity);
    }
    else {
        return outCol;
    }
}

#include mainWithOutPos(dist)
