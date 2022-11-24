precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#define OOB 1e9

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Dampening;
uniform float u_Power;
uniform float u_Shadows;
uniform mat3 u_InverseModelTransform;
uniform mat3 u_CenterTransform;


vec2 getCenter(vec2 o, vec2 u) {
    float a = dot(o, o) - 1.0;
    float b = -2.0*dot(o, u) + 2.0;
    float c = dot(u, u) - 1.0;
    float delta = b*b - 4.0*a*c;
    if (delta>=0.0) {
        float sqrtDelta = sqrt(delta);
        float l1 = (-b - sqrtDelta) / (2.0*a);
        float l2 = (-b + sqrtDelta) / (2.0*a);
        if (l1>=0.0 && l1<=1.0) return l1*o;
        else if (l2>=0.0 && l2<=1.0) return l2*o;
    }
    return vec2(OOB, OOB);
}

vec4 whirl(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);

    if (d>=1.0) {
        return texture2D(u_Tex0, proj0(pos));
    }
    else {
        float dampening = u_Dampening*0.01;

        float intensity = getMaskedParameter(u_Intensity, outPos);

//        float dangle = sign(intensity) * smoothstep(1.0, mix(0.9, -4.0, dampening), d) * 0.5/pow(d, abs(intensity)*0.04);
        float dangle = smoothstep(1.0, mix(0.9, -4.0, dampening), d) * intensity*0.05/pow(d, mix(0.01, 1.6, u_Power*0.01));

        /////
        vec2 centerMax = (u_CenterTransform*vec3(0.0, 0.0, 1.0)).xy;
        vec2 center = getCenter(centerMax, u);
        if (center.x==OOB) texture2D(u_Tex0, proj0(pos));
        float d2 = length(u-center);
        dangle = smoothstep(1.0, mix(0.9, -4.0, dampening), d2) * intensity*0.05/pow(d2, mix(0.01, 1.6, u_Power*0.01));
        /////

        float ca = cos(dangle);
        float sa = sin(dangle);
        u -= center;
        vec2 rotated = vec2(ca*u.x - sa*u.y, ca*u.y + sa*u.x)+center;
        //u += center;

        float darken = 0.0;
        if (u_Shadows!=0.0) {
            darken = smoothstep(0.005*u_Shadows, 0.0, d2);
        }
        vec2 coord = (u_ModelTransform * vec3(rotated, 1.0)).xy;
        vec4 col = texture2D(u_Tex0, proj0(coord));
//        if (darken!=0.0) {
//            vec4 hsl = RGBtoHSL(col);
//            hsl.z *= (1.0-darken);
//            return HSLtoRGB(hsl);
//        } else return col;
        return mix(col, vec4(0.0, 0.0, 0.0, col.a), darken);
    }

}

#include mainWithOutPos(whirl)
