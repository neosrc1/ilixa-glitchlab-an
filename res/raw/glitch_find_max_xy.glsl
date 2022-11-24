precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include locus

uniform float u_Intensity;
uniform float u_Phase;

vec4 getMax0(vec4 a, vec4 b) {
    return length(a.rgb) >  length(b.rgb) ? a : b;
}

vec4 getMax(vec4 a, vec4 b) {
    return RGBtoHSL(a).y >  RGBtoHSL(b).y ? a : b;
}

vec4 find(vec2 pos, vec2 outPos) {
    int N = 25;
    float delta = u_Intensity*0.0002; //1.0/u_Tex0Dim.y * u_Intensity*0.02;
    delta *= getLocus(pos);
    vec4 col = texture2D(u_Tex0, proj0(pos));
    vec2 step = mat2(cos(u_Phase), sin(u_Phase), sin(u_Phase), -cos(u_Phase)) * vec2(delta, 0.0);
    for(int i=-N; i<N; ++i) {
        col = getMax(col, texture2D(u_Tex0, proj0(pos+float(i)*step)));
        col = getMax(col, texture2D(u_Tex0, proj0(pos+float(i)*vec2(step.y, -step.x))));
    }
    return col;
}

#include mainWithOutPos(find)
