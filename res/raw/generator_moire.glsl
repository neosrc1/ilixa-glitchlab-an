precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform float u_Thickness;
uniform float u_Intensity1;
uniform float u_Intensity2;
uniform float u_Intensity3;
uniform float u_Intensity4;
uniform float u_Intensity5;

vec4 lines(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    float t = (100.0-u_Thickness)*50.0/scale;
    //float pixel = 2.0/u_Tex0Dim.y;
    u = floor(u*t+0.5)/t;

    float k1 = u_Intensity1*u_Intensity1;
    float k2 = u_Intensity2*u_Intensity2;
    float k3 = u_Intensity3*u_Intensity3;
    float k4 = u_Intensity4*u_Intensity4;
    float k5 = u_Intensity5*u_Intensity5;
    float d = u.y*u.x*k1
        + length(u)*k2
        + u.y*u.y*k3
        + u.x*u.x*k4
        + u.y*k5;
    float f = fract(d)*2.0;

    return f<=1.0 ? u_Color1 : u_Color2;
}

#include mainWithOutPos(lines)
