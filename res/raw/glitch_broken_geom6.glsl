precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform int u_Count;
uniform float u_Intensity;

//vec2 f1(vec2 u, vec2 split) {
//    vec2 v = u;
//    if (abs(v.y-split.y)<0.3) {
//        return vec2(u.x, split.y);
//        //return mix(vec2(u.x, -0.5), vec2(u.x, 0.5), v.y+0.5);
//    }
//    else {
//        return u;
//    }
//}
//
//vec2 f2(vec2 u, vec2 split) {
//    vec2 scale;
//    vec2 center;
//    if (u.x>split.x && u.y>split.y) {
//        scale = 2.0/vec2(1.0-split.x, 1.0-split.y);
//        center = vec2(1.0+split.x, 1.0+split.y)/2.0;
//    }
//    else if (u.x<=split.x && u.y>split.y) {
//        scale = 2.0/vec2(1.0+split.x, 1.0-split.y);
//        center = vec2(-1.0+split.x, 1.0+split.y)/2.0;
//    }
//    else if (u.x>split.x) {
//        scale = 2.0/vec2(1.0-split.x, 1.0+split.y);
//        center = vec2(1.0+split.x, -1.0+split.y)/2.0;
//    }
//    else {
//        scale = 2.0/vec2(1.0+split.x, 1.0+split.y);
//        center = vec2(-1.0+split.x, -1.0+split.y)/2.0;
//    }
//    u = u*scale - center*scale;
//
//    return u;
//}
//vec2 f3(vec2 u, vec2 split) {
//    float type;
//    if (u.x>split.x && u.y>split.y) {
//        type = 0.0;
//    }
//    else if (u.x<=split.x && u.y>split.y) {
//        type = 1.0;
//    }
//    else if (u.x>split.x) {
//        type = 2.0;
//    }
//    else {
//        type = 3.0;
//    }
//    type = fmod(type+float(0), 4.0);
//
//    if (type==0.0) {
//        u *= 2.0;
//    }
//    else if (type==1.0) {
//        float ox = u.x;
//        u.x = -u.y;
//        u.y = ox;
//    }
//    else if (type==2.0) {
//        float ox = u.x;
//        u.x = u.y;
//        u.y = -ox;
//    }
//    else {
//        u /= 2.0;
//    }
//
//    return u;
//}
//
//
//vec4 breakg(vec2 pos, vec2 outPos) {
//    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
////    vec2 u = (u_ModelTransform * vec3(0.0, 0.0, 1.0)).xy;
//    vec2 split = fract(u)*2.0-1.0;
//    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
//    vec2 vRatio = vec2(ratio, 1.0);
//
//    u = pos/vRatio;
//   	int N = u_Count;
//    for(int i=0; i<N; ++i) {
////        u = f2(f1(u, split), split);
//        u = f2(f1(u, split), split);
////        u = f1(u, split);
//    }
//    u *= vRatio;
//
//    return texture2D(u_Tex0, proj0(u));
//}


vec4 rep(vec2 pos, vec2 outPos) {
    vec2 u = pos;
    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);

    for(int i=0; i<u_Count; ++i) {
        vec2 m = vec2(fmod(u.x/ratio+1.0, 2.0), fmod(u.y+1.0,2.0)) - vec2(1.0, 1.0);
        if (max(abs(m.x), abs(m.y))> intensity) break;
        u = (u_ModelTransform * vec3(u, 1.0)).xy;
    }

    return texture2D(u_Tex0, proj0(u));
}


#include mainWithOutPos(rep)
