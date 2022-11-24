precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Dampening;
uniform float u_Variability;
uniform mat3 u_InverseModelTransform;

vec4 flower(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);

    if (d>=1.0) {
        return texture2D(u_Tex0, proj0(pos));
    }
    else {
        float angle = getVecAngle(u, d);
        float k = getMaskedParameter(u_Intensity, outPos);

        float variability = 1.0;
        if (u_Variability != 0.0) {
            float w = (angle+M_PI)/M_2PI*u_Count;
            float index = ceil(w);
            float dw = index-w;
            float rnd = rand2(vec2(index, index)).x;
            variability = 1.0 - u_Variability*0.01 * rnd;
        }
        if (d>=variability) {
            return texture2D(u_Tex0, proj0(pos));
        }

        float limit = 0.9 * variability;

        if (u_Dampening >= 0.0) {
            float threshold = limit * (1.0 - u_Dampening*0.01);
            if (d > threshold) {
                k *= 1.0 - (d - threshold) / (variability-threshold);
            }
        }
        else {
            if (d > limit) {
                k *= 1.0 - (d - limit) / (variability-limit);
            }
            float threshold = limit * (-u_Dampening*0.01);
            if (d < threshold) {
                k *= max(0.0, 1.0 - 2.0 * ((threshold - d) / threshold));
            }
        }


        float scaling = 1.0 + k*0.01 * (1.0+sin((angle+M_PI) * u_Count - M_PI/2.0));

        vec2 coord = (u_ModelTransform * vec3(scaling*u, 1.0)).xy;
        return texture2D(u_Tex0, proj0(coord));
    }

}

#include mainWithOutPos(flower)
