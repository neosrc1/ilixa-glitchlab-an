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
uniform float u_Phase;
uniform int u_Mode;

vec4 tex(vec2 p) {
    return (u_Tex1Transform[2][2]!=0.0) ? texture2D(u_Tex1, proj1(p)) : texture2D(u_Tex0, proj0(p));
}

vec4 getColor0(vec2 p, float ang, vec2 dim) {
    vec2 dir = vec2(cos(ang), sin(ang));
    float kx1 = dir.x==0.0 ? -1.0 : (-dim.x-p.x)/dir.x;
    float kx2 = dir.x==0.0 ? -1.0 : (dim.x-p.x)/dir.x;
    float ky1 = dir.y==0.0 ? -1.0 : (-dim.y-p.y)/dir.y;
    float ky2 = dir.y==0.0 ? -1.0 : (dim.y-p.y)/dir.y;
    float k = kx1;
    if (k<0.0 || kx2>=0.0 && kx2<k) k = kx2;
    if (k<0.0 || ky2>=0.0 && ky2<k) k = ky2;
    if (k<0.0 || ky1>=0.0 && ky1<k) k = ky1;
//    return texture2D(u_Tex0, proj0(p+k*dir));
    return tex(p+k*dir);
}

vec4 getColor2(vec2 p, float ang, vec2 bottomLeft, vec2 topRight) {
    vec2 dir = vec2(cos(ang), sin(ang));
    float kx1 = dir.x==0.0 ? -1.0 : (bottomLeft.x-p.x)/dir.x;
    float kx2 = dir.x==0.0 ? -1.0 : (topRight.x-p.x)/dir.x;
    float ky1 = dir.y==0.0 ? -1.0 : (bottomLeft.y-p.y)/dir.y;
    float ky2 = dir.y==0.0 ? -1.0 : (topRight.y-p.y)/dir.y;
    float k = kx1;
    if (k<0.0 || kx2>=0.0 && kx2<k) k = kx2;
    if (k<0.0 || ky2>=0.0 && ky2<k) k = ky2;
    if (k<0.0 || ky1>=0.0 && ky1<k) k = ky1;
    //    return texture2D(u_Tex0, proj0(p+k*dir));
    return tex(p+k*dir);
}

vec4 getColor(vec2 p, float ang, vec2 orig) {
    vec2 dir = vec2(cos(ang), sin(ang));
    float kx = dir.x==0.0 ? -1.0 : (orig.x-p.x)/dir.x;
    float ky = dir.y==0.0 ? -1.0 : (orig.y-p.y)/dir.y;
    float k = kx;
    if (k<0.0 || (ky>=k)) k = ky;
//    return k<0.0 ? vec4(100.0, 100.0, 100.0, 100.0) : texture2D(u_Tex0, proj0(p+k*dir));
    return k<0.0 ? vec4(100.0, 100.0, 100.0, 100.0) : tex(p+k*dir);
}


vec4 getColor1(vec2 p, float ang, vec2 offset, float scale) {
    vec2 dir = vec2(cos(ang), sin(ang));
    //    return texture2D(u_Tex0, proj0(p+dir));
    return tex(p+offset+dir*scale);
}



vec4 pick(vec2 pos, vec2 outPos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));
    vec4 bestColor = color;
    float bestDist = 100.0;


    float resolution = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    float scale = 1.0/ resolution;
//    vec2 pp = floor(pos/scale + 0.5);
    
//    vec2 pp = floor(pos/scale - vec2(fmod(u_ModelTransform[2][0], scale), fmod(u_ModelTransform[2][1], scale))/scale);
//    vec2 p = pp * scale;
    vec2 p =  pos;

//    float step = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]))*0.01;
//    p = floor(p/step)*step;

    vec2 dim = (u_Tex1Transform[2][2]!=0.0) ? vec2(u_Tex1Dim.x/u_Tex1Dim.y-1.0/u_Tex1Dim.y, 1.0-1.0/u_Tex1Dim.y) : vec2(u_Tex0Dim.x/u_Tex0Dim.y-1.0/u_Tex0Dim.y, 1.0-1.0/u_Tex0Dim.y);
    vec2 orig = (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy;

    vec2 scaledDim = mat2(u_ModelTransform)*(2.0*dim);
    vec2 offset = scaledDim/2.0 - orig;
    vec2 bottomLeft = floor((p+offset)/scaledDim)*scaledDim - offset;
    vec2 topRight = ceil((p+offset)/scaledDim)*scaledDim - offset;

    for(int i=0; i<u_Count; ++i) {
        float ang = float(i)/float(u_Count)*M_2PI + u_Phase;

        vec4 c;
        if (u_Mode==0) {
            c = getColor2(p, ang, bottomLeft, topRight);
        }
        else if (u_Mode==1) {
            c = getColor0(p, ang, dim);
        }
        else if (u_Mode==2) {
            c = getColor1(p, ang, -orig, resolution);
        }
        else {
            c = getColor(p, ang, orig);
        }
//        vec4 c = getColor1(p, ang);
//        vec4 c = getColor0(p, ang, dim);
//        vec4 c = getColor(p, ang, orig);
//        vec4 c = getColor2(p, ang, bottomLeft, topRight);
        float dist = length(color-c);
        if (dist<bestDist) {
            bestDist = dist;
            bestColor = c;
        }
    }

    float intensity = getLocus(pos, bestColor);
    return mix(color, bestColor, intensity);
}

#include mainWithOutPos(pick)
