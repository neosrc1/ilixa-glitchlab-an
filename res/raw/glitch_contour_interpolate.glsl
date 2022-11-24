precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include locus
#include tex(1)

uniform float u_Count;
uniform float u_Thickness;
uniform float u_Phase;
uniform vec4 u_Color1;
uniform vec4 u_Color2;


float sampleCol(vec4 color) {
    return floor((color.r + color.g + color.b)*(u_Count-1.0)/3.0 + 0.5);
}

float sample(vec2 pos) {
    vec4 color = texture2D(u_Tex1, proj1(pos));
    return sampleCol(color);
}


bool onContour(vec2 pos, vec2 p) {
    float l = sample(pos);
    return (l!=sample(pos+p.xy)) || (l!=sample(pos-p.xy)) || (l!=sample(pos+p.yx)) || (l!=sample(pos-p.yx));
}

//XXXXXXXXXXXX
bool inside(vec2 pos, float X, float Y) {
    return abs(pos.y)<=Y && abs(pos.x)<=X; //length(pos)<=1.0;
}

vec4 contour(vec2 pos, vec2 outPos) {
    float pixel = 2.0 / u_Tex0Dim.y;
    float X = u_Tex0Dim.x / u_Tex0Dim.y;//u_Tex0Dim.x>u_Tex0Dim.y ? 1.0 : u_Tex0Dim.x / u_Tex0Dim.y;
    float Y = 1.0;//u_Tex0Dim.x>u_Tex0Dim.y ? u_Tex0Dim.y / u_Tex0Dim.x : 1.0;
    vec2 p = vec2(pixel, 0.0);
    vec2 d = vec2(pixel*sin(u_Phase), pixel*cos(u_Phase));

    vec4 col = texture2D(u_Tex1, proj1(pos));
    float s = sampleCol(col);

    vec2 pos1 = pos;
    while (sample(pos1+d)==s && inside(pos1+d, X, Y)) {
        pos1 += d;
    }
    vec4 col1 = texture2D(u_Tex1, proj1(pos1));

    vec2 pos2 = pos;
    while (sample(pos2-d)==s && inside(pos2-d, X, Y)) {
        pos2 -= d;
    }
    vec4 col2 = texture2D(u_Tex1, proj1(pos2));

    vec2 dd = pos2-pos1;
    float len = length(dd);
    if (len==0.0) return col;

    vec4 outCol = mix(col1, col2, dot((pos-pos1)/len, (pos2-pos1)/len));
//    color = onContour(pos, p) ? u_Color2 : u_Color1;
//    color = sum > 0.0 ? u_Color2 : u_Color1;

    return mix(texture2D(u_Tex0, proj0(pos)), outCol, getLocus(pos));
}

#include mainWithOutPos(contour)
