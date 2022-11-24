precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include locuswithcolor
#include tex(1)

uniform float u_Intensity;
uniform int u_Count;
uniform float u_ScaleX;
uniform float u_ScaleY;

vec4 tex(vec2 p) {
    return (u_Tex1Transform[2][2]!=0.0) ? texture2D(u_Tex1, proj1(p)) : texture2D(u_Tex0, proj0(p));
}

vec4 pick(vec2 pos, vec2 outPos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));
    vec4 bestColor = color;
    float bestDist = 100.0;


    float resolution = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    float scale = 1.0/ resolution;
    vec2 p =  pos;


    vec2 dim = (u_Tex1Transform[2][2]!=0.0) ? vec2(u_Tex1Dim.x/u_Tex1Dim.y-1.0/u_Tex1Dim.y, 1.0-1.0/u_Tex1Dim.y) : vec2(u_Tex0Dim.x/u_Tex0Dim.y-1.0/u_Tex0Dim.y, 1.0-1.0/u_Tex0Dim.y);
    vec2 orig = (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy;

    vec2 scaledDim = mat2(u_ModelTransform)*(2.0*dim);
    vec2 offset = scaledDim/2.0 - orig;
    vec2 bottomLeft = floor((p+offset)/scaledDim)*scaledDim - offset;
    vec2 topRight = ceil((p+offset)/scaledDim)*scaledDim - offset;
//    vec2 bottomLeft = (floor((p+offset)/scaledDim+0.5)-0.5)*scaledDim - offset;
//    vec2 topRight = (ceil((p+offset)/scaledDim+0.5)-0.5)*scaledDim - offset;

    float dist;
    vec2 pp;
    vec4 c;

    float N = max(1.0, floor(float(u_Count)/2.0)-1.0);
    for(float i=0.0; i<float(u_Count); ++i) {
        float d = floor(i/2.0)/N;
        if (fmod(i, 2.0)==0.0) {
            pp = vec2(bottomLeft.x + d*(topRight.x-bottomLeft.x), bottomLeft.y + fmod(p.y*u_ScaleY, topRight.y-bottomLeft.y));
            c = tex(pp);
            dist = length(color-c);
            if (dist<bestDist) {
                bestDist = dist;
                bestColor = c;
            }
        }
        else {
            pp = vec2(bottomLeft.x + fmod(p.x*u_ScaleX, topRight.x-bottomLeft.x), bottomLeft.y + d*(topRight.y-bottomLeft.y));
            c = tex(pp);
            dist = length(color-c);
            if (dist<bestDist) {
                bestDist = dist;
                bestColor = c;
            }
        }
    }

    float intensity = getLocus(pos, bestColor);
    return mix(color, bestColor, intensity);
}

#include mainWithOutPos(pick)
