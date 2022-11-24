precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include smoothrandom

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Dampening;
uniform float u_Tolerance;
uniform vec4 u_Color;



float dampenSLinear(float x, float maxLen) {
    if (x>=1.0-maxLen) return 1.0;
    x = x/(1.0-maxLen);
    if (x<0.33333333) {
        return x*x*9.0*0.25;
    }
    else if (x<=0.666666667) {
        return (x*1.5)-0.25;
    }
    else {
        x = 1.0-x;
        x = x*x*9.0*0.25;
        return 1.0-x;
    }
}

float centrality(vec2 pos, float r) {
    float d = length(pos) / r;
    if (d<=0.6) return 1.0;
    else if (d>=1.0) return 0.0;
    else {
        return 1.0 - dampenSLinear((d-0.6)*2.5, 0.0);
    }
}

float colorWeight(vec4 color) {
    float d = length(color.rgb-u_Color.rgb);
    float maxDistance = u_Tolerance*0.01*1.7320508075688772;
    if (d>maxDistance) return 0.0;
    if (d<maxDistance/2.0) return 1.0;
    return 1.0 - dampenSLinear((d-0.5)*2.0, 0.0);
}

vec4 ghost(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec4 totalColor = vec4(0.0, 0.0, 0.0, 0.0);
    float totalWeight = 0.0;
    vec2 delta = (u-pos) / u_Count;
    float radius = min(1.0, u_Tex0Dim.x/u_Tex0Dim.y)*1.1;

    vec2 p = pos;
    for(int i=0; i<int(u_Count); ++i) {
        vec4 color = texture2D(u_Tex0, proj0(p));
        float weight = pow(1.0-u_Dampening*0.01, float(i)/(u_Count-1.0)) * (i==0 ? 1.0 : centrality(p, radius)*colorWeight(color));
        totalColor += weight * color;
        totalWeight += weight;
        p += delta;
    }

    return totalColor / totalWeight;
}

#include mainWithOutPos(ghost)
