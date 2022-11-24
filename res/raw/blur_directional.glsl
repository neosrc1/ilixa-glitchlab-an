precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform float u_Dampening;
uniform mat3 u_InverseModelTransform;

vec4 dirBlur(vec2 pos, vec2 outPos) {
    float intensity = getMaskedParameter(u_Intensity, outPos);

    vec2 origin = (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy;
    vec2 one = (u_ModelTransform*vec3(1.0, 0.0, 1.0)).xy;

    vec2 p = one - origin;
    if (p.x==0.0 && p.y==0.0) return texture2D(u_Tex0, proj0(pos));

    vec2 dir = normalize(p);
    float stepLen = 2.0/u_Tex0Dim.y;
    float ratio = (u_Tex0Dim.x/u_Tex0Dim.y);
    vec2 step = dir * stepLen;

    float distance = intensity*0.005;
    if (distance <= stepLen) return texture2D(u_Tex0, proj0(pos));

    float n = 0.0;
    vec4 totalColor = vec4(0.0, 0.0, 0.0, 0.0);
    float maxBack = length(pos - (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy);
    p = pos - distance*0.5*dir;
    for(float d=0.0; d<distance; d+=stepLen) {
        totalColor += texture2D(u_Tex0, proj0(p));
        p += step;
        ++n;
    }

    return totalColor / n;

}


#include mainWithOutPos(dirBlur)
