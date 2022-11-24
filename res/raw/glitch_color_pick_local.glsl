precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include locuswithcolor_nodep
#include tex(1)

uniform float u_Intensity;
uniform int u_Count;
uniform float u_Phase;
uniform float u_Mode;

vec4 tex(vec2 p) {
    return (u_Tex1Transform[2][2]!=0.0) ? texture2D(u_Tex1, proj1(p)) : texture2D(u_Tex0, proj0(p));
}

vec4 pick(vec2 pos, vec2 outPos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));
    vec4 bestColor = color;
    float bestDist = 100.0;


    float resolution = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    float scale = 1.0/ resolution;

    vec2 dim = vec2(u_Tex0Dim.x/u_Tex0Dim.y-1.0/u_Tex0Dim.y, 1.0-1.0/u_Tex0Dim.y);
    vec2 orig = (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy;

    vec2 scaledDim = mat2(u_ModelTransform)*(1.0*dim);
    vec2 offset = -vec2(u_ModelTransform[2][0], u_ModelTransform[2][1])/scaledDim;
    float N = float(u_Count);
    vec2 step = N<=1.0? vec2(0.0, 0.0) : vec2(cos(u_Phase), sin(u_Phase))*scaledDim*2.0/(N-1.0);//*scaledDim*0.05;
    vec2 start = -step*scaledDim;
    int zeroDists = 0;
    for (float i=0.0; i<N; ++i) {
        vec2 pos1 = pos + offset + start + i*step;
        float ang = i/float(u_Count)*M_2PI + u_Phase;
        vec2 pos2 = pos + offset + vec2(cos(ang), sin(ang))*scaledDim;
        vec2 p = mix(pos1, pos2, u_Mode*0.01);
        vec4 c = tex(p);
        float dist = length(color-c);
        if (dist<bestDist) {
            if (i==0.0 || dist!=0.0 || zeroDists!=0) {
                bestDist = dist;
                bestColor = c;
            }
            else if (dist==0.0) {
                ++zeroDists;
            }
        }
    }

    float intensity = getLocus(pos, color, bestColor);
    return mix(color, bestColor, intensity);
}

#include mainWithOutPos(pick)
