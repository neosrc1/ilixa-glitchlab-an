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

vec4 ghostMax(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec4 totalColor = vec4(0.0, 0.0, 0.0, 0.0);
    float totalWeight = 0.0;
    vec2 delta = (u-pos) / u_Count;
    float radius = min(1.0, u_Tex0Dim.x/u_Tex0Dim.y)*1.1;

    vec2 p = pos;
    for(int i=0; i<int(u_Count); ++i) {
        vec4 color = texture2D(u_Tex0, proj0(p));
        if (pow(1.0-u_Dampening*0.01, float(i)/(u_Count-1.0))*(color.r+color.g+color.b) >= totalColor.r+totalColor.g+totalColor.b) totalColor = color;
        p += delta;
    }

    return totalColor;
}

#include mainWithOutPos(ghostMax)
