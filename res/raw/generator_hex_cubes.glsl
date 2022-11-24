precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hexagon

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform vec4 u_Color3;
uniform vec4 u_Color4;
uniform float u_Thickness;

vec4 lines(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec4 hex = hexPolarCoords(u);
    if (hex.y<u_Thickness*0.005) return u_Color4;
    else if (hex.x<-M_PI/3.0) return u_Color1;
    else if (hex.x<M_PI/3.0) return u_Color2;
    else return u_Color3;
}

#include mainWithOutPos(lines)
