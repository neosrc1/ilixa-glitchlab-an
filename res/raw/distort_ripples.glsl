precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Dampening;
uniform mat3 u_InverseModelTransform;

vec4 ripples(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);

    if (d>=1.0) {
        return texture2D(u_Tex0, proj0(pos));
    }
    else {
        float dampen = u_Dampening >= 0.0 ? pow(1.0-d, u_Dampening*0.02) : pow(d, -u_Dampening*0.05);
        float intensity = getMaskedParameter(u_Intensity, outPos);
        float dilation = 1.0 + intensity*0.01 * sin(d * u_Count * M_PI) * dampen;
        vec2 coord = (u_ModelTransform * vec3(dilation*u, 1.0)).xy;
        return texture2D(u_Tex0, proj0(coord));
    }

}

#include mainWithOutPos(ripples)
