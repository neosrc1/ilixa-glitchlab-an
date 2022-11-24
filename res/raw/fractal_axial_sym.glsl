precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include perspective

uniform vec4 u_Color1;
uniform float u_Thickness;
uniform int u_Count;


//vec4 axialsym(vec2 pos, vec2 outPos) {
//    vec2 a = vec2(0.0, 0.0);
//    vec2 b = vec2(1.0, 0.0);
//
//    vec2 coord = pos;
//    vec2 u = coord;
//    for(int i=0; i<u_Count; ++i) {
//        a = (u_ModelTransform * vec3(a, 1.0)).xy;
//        b = (u_ModelTransform * vec3(b, 1.0)).xy;
//        coord = u;
//        vec2 normal = normalize(vec2(b.y-a.y, a.x-b.x));
//        vec2 posRelToAxis = coord-a;
//        float distanceFromAxis = dot(normal, posRelToAxis);
//        if (abs(distanceFromAxis) < u_Thickness*0.01) {
//            return u_Color1;
//        }
//        vec2 coord = distanceFromAxis<0.0 ? reflect(posRelToAxis, normal)+a : coord;
//        u = (u_ModelTransform * vec3(coord, 1.0)).xy;
//    }
//
//    return texture2D(u_Tex0, proj0(coord));
//
//}

vec4 axialsym(vec2 pos, vec2 outPos) {
    vec2 u = pos;
    for(int i=0; i<u_Count; ++i) {
        if (abs(u.x) < u_Thickness*0.01) {
            return u_Color1;
        }
        if (u.x<0.0) u = -u;
//        if (u.x<0.0) break;
        if (i<u_Count) u = (u_ModelTransform * vec3(u, 1.0)).xy;
    }

    return texture2D(u_Tex0, proj0(u));

}

#include mainWithOutPosAndPerspectiveFit(axialsym)