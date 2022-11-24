precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Count;
uniform mat3 u_InverseModelTransform;

vec4 streak(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    if (abs(u.y)<1.0) {
        float stride = 2.0/u_Count;
        float y = u.y+1.0;
        float y1 = floor(y/stride)*stride-1.0;
        float y2 = y1+stride;
        vec2 p1 = (u_InverseModelTransform * vec3(u.x, y1, 1.0)).xy;
        vec2 p2 = (u_InverseModelTransform * vec3(u.x, y2, 1.0)).xy;
        return mix(texture2D(u_Tex0, proj0(p1)), texture2D(u_Tex0, proj0(p2)), (y-y1)/stride);
//        vec2 p1 = (u_InverseModelTransform * vec3(u.x, -1.0, 1.0)).xy;
//        vec2 p2 = (u_InverseModelTransform * vec3(u.x, 1.0, 1.0)).xy;
//        return mix(texture2D(u_Tex0, proj0(p1)), texture2D(u_Tex0, proj0(p2)), (u.y+1.0)*0.5);
    }
    return texture2D(u_Tex0, proj0(pos));
}

#include mainWithOutPos(streak)
