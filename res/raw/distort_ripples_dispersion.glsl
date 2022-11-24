precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Dampening;
uniform mat3 u_InverseModelTransform;
uniform float u_Dispersion;

vec4 getRGBWeights(float w) {
    return vec4(
        max(0.0, -w),
        max(0.0, 1.0-abs(w)),
        max(0.0, w),
        1.0
    );
}

vec4 ripples(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);

    if (d>=1.0) {
        return texture2D(u_Tex0, proj0(pos));
    }
    else {
        float dampen = u_Dampening >= 0.0 ? pow(1.0-d, u_Dampening*0.02) : pow(d, -u_Dampening*0.05);
        float intensity = getMaskedParameter(u_Intensity, outPos);
        if (u_Dispersion==0.0) {
            float dilation = 1.0 + intensity*0.01 * sin(d * u_Count * M_PI) * dampen;
            vec2 coord = (u_ModelTransform * vec3(dilation*u, 1.0)).xy;
            return texture2D(u_Tex0, proj0(coord));
        }
        else {
            float wStep = 0.05;
            vec4 totalColor = vec4(0.0, 0.0, 0.0, 0.0);
            vec4 totalWeight = vec4(0.0, 0.0, 0.0, 0.0);
            float dispersion = u_Dispersion*0.1;
            for(float w=-1.0; w<=1.0; w+=wStep) {
                float dilation = 1.0 + intensity*(1.0+w*dispersion)*0.01 * sin(d * u_Count * M_PI) * dampen;
                vec2 coord = (u_ModelTransform * vec3(dilation*u, 1.0)).xy;
                vec4 weight = getRGBWeights(w);
                totalColor += weight*texture2D(u_Tex0, proj0(coord));
                totalWeight += weight;
            }
            return totalColor / totalWeight;
        }
    }

}

#include mainWithOutPos(ripples)
