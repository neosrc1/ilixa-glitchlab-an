precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform vec4 u_Color1;
uniform float u_Thickness;
uniform mat3 u_Transform1;
uniform mat3 u_Transform2;
uniform int u_Orientation;


vec4 sym(vec2 pos, vec2 outPos) {
    vec2 a = (u_Transform1 * vec3(pos, 1.0)).xy;
    vec2 b = (u_Transform2 * vec3(pos, 1.0)).xy;
    vec2 u;
    if (u_Orientation==0) {
        if (pos.x<0.0) u = a;
        else u = b;
    }
    else {
        if (pos.y<0.0) u = a;
        else u = b;
    }

    return texture2D(u_Tex0, proj0(u));

}

#include mainWithOutPos(sym)
