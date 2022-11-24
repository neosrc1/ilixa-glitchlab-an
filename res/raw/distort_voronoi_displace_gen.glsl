precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Intensity;
uniform float u_RadiusVariability;
uniform float u_Variability;
uniform float u_Perturbation;
uniform float u_Distortion;
uniform float u_LowResColorBleed;
uniform mat3 u_InverseModelTransform;
uniform float u_Count;
#include capped_vec2array(u_Centers,1024)
#include capped_vec2array(u_Displacements,1024)

//uniform vec2 u_Centers[128];
//uniform vec2 u_Displacements[128];

vec4 displace(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy; //transform(pos, center, scale);

    if (u_Perturbation > 0.0) {
        t = perlinDisplace(t, 3, u_Perturbation*0.04);
    }


    float d2min = 1000000000.0;
    float d2min2 = 1000000000.0;
    vec2 minCenter;
    float minIndex = 0.0;

//    float N = 60.0;
    float N = u_Count;
    for(float i=0.0; i<N; ++i) {
        float angle = i*3.0*M_4PI/N;
        vec2 center = u_Centers[int(i)];
//        vec2 center = (i*0.3+1.0) * vec2(cos(angle), sin(angle));
//        if (u_Variability!=0.0) {
//            center += rand2(vec2(i, i)) * (u_Variability-50.0)*0.1;
//        }

        vec2 d = t - center;
        float d2 = dot(d, d);

        if (d2 < d2min) {
            d2min2 = d2min;
            d2min = d2;
            minIndex = i;
            minCenter = center;
        }
        else if (d2 < d2min2) {
            d2min2 = d2;
        }
    }

    float intensity = getMaskedParameter(u_Intensity, outPos);
    vec2 delta = (rand2(vec2(minIndex+1.0, minIndex))-vec2(0.5, 0.5)) * intensity*0.02;
    vec2 newPos = pos + delta;

    bool distorted = false;
    if (d2min > 0.0 && u_Distortion > 0.0 && u_LowResColorBleed!=100.0) {
            vec2 dd = t - minCenter;
            distorted = true;
            float k = clamp(sqrt(d2min), 0.0, 1.0) / sqrt(d2min2);
//            float k = sqrt(d2min / d2min2);
            float r = 1.0-k;
            float dp = u_Distortion*0.02 * (1.0-r)/(0.5+r);
            newPos += dd * dp;
    }

    vec4 outColor = texture2D(u_Tex0, proj0(newPos));

    if (u_LowResColorBleed != 0.0) {
        vec2 pixelPos = (u_InverseModelTransform * vec3(minCenter, 1.0)).xy + delta;
        outColor = mix(outColor, texture2D(u_Tex0, proj0(pixelPos)), u_LowResColorBleed*0.01);
    }

    return outColor;

}

#include mainWithOutPos(displace)
