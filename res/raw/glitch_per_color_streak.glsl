precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include locuswithcolor

uniform float u_Count;
uniform float u_Thickness;
uniform float u_Phase;
uniform vec4 u_Color1;
uniform vec4 u_Color2;


float sampleCol(vec4 color) {
    return floor((color.r + color.g + color.b)*(u_Count-1.0)/3.0 + 0.5);
}

float sample(vec2 pos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));
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

    vec4 col = texture2D(u_Tex0, proj0(pos));
    float bestDist = 1e9;
    float ang = 0.0;
    float bestAng = 0.0;
    for(float r = 0.25; r<1.0; r+=0.5) {
        for(float g = 0.25; g<1.0; g+=0.5) {
            for(float b = 0.25; b<1.0; b+=0.5) {
                float dist = length(col.rgb-vec3(r, g, b));
                if (dist<bestDist) { bestAng = ang; bestDist = dist; }
                ang += M_PI/4.0;
            }
        }
    }
    ang = bestAng + u_Phase;
    vec2 d = vec2(pixel*sin(ang), pixel*cos(ang));

    float s = sampleCol(col);

    vec2 pos1 = pos;
    while (sample(pos1+d)==s && inside(pos1+d, X, Y)) {
        pos1 += d;
    }
    vec4 col1 = texture2D(u_Tex0, proj0(pos1));

    vec2 pos2 = pos;
    while (sample(pos2-d)==s && inside(pos2-d, X, Y)) {
        pos2 -= d;
    }
    vec4 col2 = texture2D(u_Tex0, proj0(pos2));

    vec2 dd = pos2-pos1;
    float len = length(dd);
    if (len==0.0) return col;

    //vec4 outCol = mix(col1, col2, dot((pos-pos1)/len, (pos2-pos1)/len));
    vec4 outCol = texture2D(u_Tex0, proj0(mix(pos1, pos2, 0.5)));//mix(col1, col2, dot((pos-pos1)/len, (pos2-pos1)/len));
//    color = onContour(pos, p) ? u_Color2 : u_Color1;
//    color = sum > 0.0 ? u_Color2 : u_Color1;

    return mix(col, outCol, getLocus(pos, col, outCol));
}

#include mainWithOutPos(contour)
