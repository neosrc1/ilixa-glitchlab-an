precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;
uniform float u_Count;

vec4 sphereMap(vec3 dir) {
    vec3 n = normalize(dir);
    float alpha = getVecAngle(n.xz);
    float beta = asin(n.y);
    float ratio = (u_Tex0Dim.x/u_Tex0Dim.y);
    float nX = u_Count*2.0;
    float nY = u_Count;
    return texture2D(u_Tex0, vec2(-alpha/M_PI*0.5*nX, 0.5+nY*beta/M_PI));
}

vec4 planar(vec2 pos, vec2 outPos) {
    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;

    return sphereMap(dir);
}

#include mainWithOutPos(planar)
