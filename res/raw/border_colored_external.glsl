precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Left;
uniform float u_Right;
uniform float u_Top;
uniform float u_Bottom;
uniform vec4 u_Color;

vec4 border(vec2 pos, vec2 outPos) {
    float ratio = u_outDim.x / u_outDim.y;
    //float border = u_Thickness*2.0;
    if (pos.y<-1.0+u_Top*2.0 || pos.y>1.0-u_Bottom*2.0 || pos.x<-ratio+u_Left*2.0 || pos.x>ratio-u_Right*2.0) {
        return u_Color;
    }

    return texture2D(u_Tex0, proj0(pos));

}

#include mainWithOutPos(border)
