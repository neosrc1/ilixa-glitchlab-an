precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform float u_Thickness;

vec4 lines(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

//    return fmod(floor(u.x), 2.0)==0.0 ? u_Color1 : u_Color2;
    return fmod(u.x, 1.0+u_Thickness*0.02)<=1.0 ? u_Color1 : u_Color2;
}

#include mainWithOutPos(lines)
