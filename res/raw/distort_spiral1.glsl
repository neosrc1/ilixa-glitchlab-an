precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Dampening;
uniform float u_Ratio;
uniform mat3 u_InverseModelTransform;
uniform float u_Phase;
uniform int u_Mirror;

vec4 spiral(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);

    float intensity = getMaskedParameter(u_Intensity, outPos);
    float p = intensity > 0.0 ? 1.0/(1.0+intensity*0.1) : 1.0+pow(-intensity, 0.75);

    float angle = getVecAngle(u, d);

    float phase = u_Phase;
    float widthAngle = M_PI/4.0;

    if (u_Mirror==1) {
        angle = 2.0*(angle + phase);
        angle = fmod(angle, M_4PI);
        if (angle > M_2PI) { angle = M_4PI-angle; }
    }
    else {
        angle = angle + phase;
        angle = fmod(angle, M_2PI);
    }
    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    float theta = log(1.0 + d)/p;
    float lambda = u_Count * fmod(angle + theta, M_2PI);
    theta = fmod(theta, 2.0*widthAngle);

    float sx = 2.0 * theta/widthAngle * ratio;
    float sy = 2.0 * lambda/M_2PI;

    vec2 coord = vec2(sx, sy);
    return texture2D(u_Tex0, proj0(coord));
}

#include mainWithOutPos(spiral)
