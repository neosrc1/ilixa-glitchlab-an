precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include perspective

uniform vec4 u_Color1;
uniform float u_Thickness;


vec4 axialsym(vec2 pos, vec2 outPos) {
    vec2 a = (u_ModelTransform * vec3(vec2(0.0, 0.0), 1.0)).xy;
    vec2 b = (u_ModelTransform * vec3(vec2(1.0, 0.0), 1.0)).xy;

    vec2 normal = normalize(vec2(b.y-a.y, a.x-b.x));
    vec2 posRelToAxis = pos-a;
    float distanceFromAxis = dot(normal, posRelToAxis);
    if (abs(distanceFromAxis) < u_Thickness*0.01) {
        return u_Color1;
    }
    vec2 coord = distanceFromAxis<0.0 ? reflect(posRelToAxis, normal)+a : pos;

    return texture2D(u_Tex0, proj0(coord));

}

#include mainWithOutPosAndPerspectiveFit(axialsym)