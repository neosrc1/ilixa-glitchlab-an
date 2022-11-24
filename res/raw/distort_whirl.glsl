precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
//#include hsl

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Balance;
uniform float u_Shadows;
uniform mat3 u_InverseModelTransform;

vec4 whirl(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);

    if (d>=1.0) {
        return texture2D(u_Tex0, proj0(pos));
    }
    else {
        float bal = (-u_Balance+100.0)*0.005;
        if (bal != 0.5) {
            if (bal==1.0 || d < bal) {
                float ratio2 = d/bal;
                d = 0.5 * ratio2;
            }
            else {
                float ratio2 = (d-bal)/(1.0-bal);
                d = 0.5 * (1.0-ratio2);
            }
        }

        float intensity = getMaskedParameter(u_Intensity, outPos);

        float dangle = intensity * 0.1 * (1.0-cos(d*2.0*M_PI));
        float ca = cos(dangle);
        float sa = sin(dangle);
        vec2 rotated = vec2(ca*u.x - sa*u.y, ca*u.y + sa*u.x);

        float darken = 0.0;
        if (u_Shadows!=0.0) {
            float d = length(rotated*vec2(min(1.5, 1.00+abs(u_Intensity*0.03)), 1.0));
            float sHeight = u_Shadows*0.04;
            float sSlope = 1.0+u_Shadows*0.03;
            darken = clamp(sHeight-d*sSlope, 0.0, 1.0);
//            darken *= u_Shadows*0.01;
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
