precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Dampening;
uniform mat3 u_InverseModelTransform;

vec4 bump(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);

    if (d==0.0 || d>=1.0) {
        return texture2D(u_Tex0, proj0(pos));
    }
    else {
        float intensity = getMaskedParameter(u_Intensity, outPos);
        float k = d*d;
        float dilation;
        if (intensity <= 0.0) {
            dilation = pow(k, intensity*0.025);
        }
        else {
            float b = 1.0 - intensity * 0.02;
    //        float a = 1 - b;
            dilation = b + k * (1.0-b);
        }

        float dampening = 0.01*u_Dampening;
        if (dampening>0.0 && d>1.0 - dampening) {
            dilation = mix(1.0, dilation, (1.0-d)/dampening);
        }
        else if (dampening<0.0) {
            dilation *= 1.0-dampening*dampening*0.25*pow(d*2.0, -4.0*dampening);
        }

        vec2 coord = (u_ModelTransform * vec3(dilation*u, 1.0)).xy;
        return texture2D(u_Tex0, proj0(coord));
    }

}

#include mainWithOutPos(bump)
