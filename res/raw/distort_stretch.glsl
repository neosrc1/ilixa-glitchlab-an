precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform float u_Dampening;
uniform mat3 u_InverseModelTransform;

vec4 stretch(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);

    float p = 1.1;
    float radius = 1.0;
    float maxRadius = sqrt(u_InverseModelTransform[0][0]*u_InverseModelTransform[0][0] + u_InverseModelTransform[0][1]*u_InverseModelTransform[0][1])*0.75;

    float intensity = getMaskedParameter(u_Intensity, outPos);
    float dilation = pow(2.0, intensity/20.0);
    if (d >= radius) {
        float a = maxRadius*(dilation-1.0) * pow(maxRadius-radius, -p);

        /*float k = 1;
        if (d < radius*1.3f) {
            k = (d-radius) / (radius*0.3f);
        }*/

        dilation = dilation - a*pow(d-radius, p)/d; // requires a completely different formula if we want to remove the flat inner circle.
    }


    vec2 coord = (u_ModelTransform * vec3(dilation*u, 1.0)).xy;
    return texture2D(u_Tex0, proj0(coord));

}

#include mainWithOutPos(stretch)
