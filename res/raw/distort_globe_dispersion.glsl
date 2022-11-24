precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include smoothrandom

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Dampening;
uniform float u_Perturbation;
uniform float u_Seed;
uniform float u_Power;
uniform float u_Dispersion;

uniform mat3 u_InverseModelTransform;

vec4 getRGBWeights(float w) {
    return vec4(
        max(0.0, -w),
        max(0.0, 1.0-abs(w)),
        max(0.0, w),
        1.0
    );
}

vec4 globe(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;
    if (u_Perturbation > 0.0) {
        u += sineSurfaceRand2Seeded(u*(1.0+u_Perturbation*0.01), u_Seed) * 0.01*u_Perturbation;
    }

    //float d = length(u);
    float p = u_Power;//*0.05;
    float d = pow(pow(abs(u.x), p) + pow(abs(u.y), p), 1.0/p);

    if (d==0.0 || d>=1.0) {
        return texture2D(u_Tex0, proj0(pos));
    }
    else {
        float hh = sqrt(1.0 - d*d);
        if (hh == 0.0) {
            return texture2D(u_Tex0, proj0(pos));
        }

        float h = 1.0 + hh;
        float intensity = getMaskedParameter(u_Intensity, outPos);


        if (u_Dispersion==0.0) {
            float s = (- d * intensity*0.01) / hh;
            float dilation = 1.0 + (h * s)/d;
            vec2 coord = (u_ModelTransform * vec3(dilation*u, 1.0)).xy;
            return texture2D(u_Tex0, proj0(coord));
        }
        else {
            float wStep = 0.05;
            vec4 totalColor = vec4(0.0, 0.0, 0.0, 0.0);
            vec4 totalWeight = vec4(0.0, 0.0, 0.0, 0.0);
            float dispersion = u_Dispersion*0.01;
            for(float w=-1.0; w<=1.0; w+=wStep) {
                float s = (- d * (intensity*(1.0+w*dispersion))*0.01) / hh;
                float dilation = 1.0 + (h * s)/d;
                vec2 coord = (u_ModelTransform * vec3(dilation*u, 1.0)).xy;
                vec4 weight = getRGBWeights(w);
                totalColor += weight*texture2D(u_Tex0, proj0(coord));
                totalWeight += weight;
            }
            return totalColor / totalWeight;
        }
    }

}

#include mainWithOutPos(globe)
