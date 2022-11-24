precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include locuswithcolor_nodep

uniform mat3 u_InverseModelTransform;

vec4 streak(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    if (abs(u.y)<1.0) {
        u.y = 0.0;
    }
    else {
        u.y -= sign(u.y);
    }
    vec2 p = (u_InverseModelTransform * vec3(u, 1.0)).xy;
    vec4 outColor = texture2D(u_Tex0, proj0(p));
    vec4 col = texture2D(u_Tex0, proj0(pos));
    float locIntensity = getLocus(pos, col, outColor);
    return mix(col, outColor, locIntensity);
}

#include mainWithOutPos(streak)
