precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform mat3 u_InverseModelTransform;

vec4 stretch(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);
    float radius = 1.0;
    float maxRadius = sqrt(u_InverseModelTransform[0][0]*u_InverseModelTransform[0][0] + u_InverseModelTransform[0][1]*u_InverseModelTransform[0][1]);

    float intensity = getMaskedParameter(u_Intensity, outPos);

    vec2 v;
    if (d<=radius) {
        v = u;
    }
    else {
    //return vec4(0.0, 0.0, 0.0, 1.0);
        float p = 1.0/intensity;
        float e = pow(d/radius, p);
        float k = d>=radius*2.0 ? 1.0 : (d-radius)/radius;
//        v = u/d * mix((1.0 + (e - 1.0)/p), e, k);
        v = u/d * mix(d, e, k);
//        v = u/d * e;
    }

    vec2 coord = (u_ModelTransform * vec3(v, 1.0)).xy;
    return texture2D(u_Tex0, proj0(coord));

}

#include mainWithOutPos(stretch)
