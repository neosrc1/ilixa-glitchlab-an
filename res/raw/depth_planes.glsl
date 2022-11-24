precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include tex(1)

uniform float u_Intensity;
uniform float u_Dampening;

float height(vec4 color) {
    return 1.0 - (color.r + color.g + color.b)/3.0;
}

vec2 getIntersectDelta(vec2 center, vec2 p, float h) {
    return (p-center) / (1.0 + h*u_Intensity*0.1);
}

bool inBounds(vec2 p, float ratio) {
    return p.x>=-ratio && p.x<=ratio
        && p.y>=-1.0 && p.y<=1.0;
}

vec4 planes(vec2 pos, vec2 outPos) {
    vec2 center = (u_ModelTransform * vec3(0.0, 0.0, 1.0)).xy;
    float scale = sqrt(u_ModelTransform[0][0]*u_ModelTransform[0][0] + u_ModelTransform[1][0]*u_ModelTransform[1][0]);

//    pos = pos/scale;
    vec2 dir = pos-center;
    float len = length(dir);
    if (len == 0.0) return texture2D(u_Tex0, proj0(pos));

    vec2 normedDir = dir/len;
    float d = dot(normedDir, dir);
    float dd = 0.0;
    vec2 step = 2.0 * normedDir / u_Tex0Dim.y;
    bool heightMap = u_Tex1Transform[2][2]!=0.0;

//    int maxSteps = 250;
    vec2 p = pos;
    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
    float h = 0.0;
    float prevDd;
    vec4 prevColor = vec4(0.0, 0.0, 0.0, 1.0);
    float prevH;
    float ratio = u_Tex0Dim.x / u_Tex0Dim.y;
    do {
        prevColor = color;
        prevDd = dd;
        prevH = h;

        color = texture2D(u_Tex0, proj0(p));
        h = heightMap ? height(texture2D(u_Tex1, proj1(p))) : height(color);
        vec2 intersect = getIntersectDelta(center, p, h);
        dd = dot(normedDir, intersect);

        p += step;
//        --maxSteps;
    } while (inBounds(p, ratio) && dd<d);

    if (!inBounds(p, ratio)) return vec4(0.0, 0.0, 0.0, 1.0);
    else {
        float k = (d-prevDd)/(dd-prevDd);
        float hh = mix(prevH, h, k);
        float darken = 1.0 + u_Dampening*0.02*(0.5-hh);
        return mix(prevColor, color, k) * vec4(darken, darken, darken, 1.0);
    }


}

#include mainWithOutPos(planes)
