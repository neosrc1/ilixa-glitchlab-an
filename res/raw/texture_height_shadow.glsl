precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform float u_Dampening;
uniform vec2 u_Direction;

float height(vec2 p) {
    vec4 color = texture2D(u_Tex0, proj0(p));
    return (color.r + color.g + color.b) / 3.0;
}

vec4 shadow(vec2 pos, vec2 outPos) {
    float intensity = getMaskedParameter(u_Intensity, outPos);

    vec4 color = texture2D(u_Tex0, proj0(pos));
//    return vec4(u_Direction.x, u_Direction.y, color.b, color.a);
    if (u_Direction.x!=0.0 || u_Direction.y!=0.0) {
        float stepLen = 2.0/u_Tex0Dim.y;
        float ratio = (u_Tex0Dim.x/u_Tex0Dim.y);
        vec2 step = normalize(u_Direction) * stepLen;
        if (abs(step.x) > abs(step.y)) {
            step *= abs(stepLen/step.x);
        }
        else {
            step *= abs(stepLen/step.y);
        }

        float iters = 0.0;
        float dh = length(step) / length(u_Direction);
        vec2 p = pos;
        float h = height(p);
        int N = 2;
        int consecutives = 0;
        while (h < 1.0) {
            p += step;
            if (p.x<-ratio || p.x>ratio || p.y<-1.0 || p.y>1.0) {
//                float g = iters/u_Tex0Dim.y;
//                return vec4(g, 1.0, g, 1.0);
                return color;
            }

            h += dh;
            float hh = height(p);
            if (h < hh) {
//                float g = iters/u_Tex0Dim.y;
//                return vec4(g, g, 1.0, 1.0);
                ++consecutives;
                if (consecutives == N) {
                    float darken = 1.0 - intensity*0.01 * pow(1.0-u_Dampening*0.001, 1000.0*iters/u_Tex0Dim.y);
                    return vec4(color.rgb * darken, color.a);
                }
            }
            else {
                consecutives = 0;
            }
            ++iters;
        }

//        float g = iters/u_Tex0Dim.y;
//        return vec4(g, g, g, 1.0);
    }

    return color;
//    return vec4(1.0, 0.0, 0.0, 1.0);
}


#include mainWithOutPos(shadow)
