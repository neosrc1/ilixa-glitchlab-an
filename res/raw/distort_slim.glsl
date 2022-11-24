precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform float u_Dampening;
uniform mat3 u_InverseModelTransform;

vec4 slim(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float ratio = u_Tex0Dim.x / u_Tex0Dim.y;
    float xMin = 0.5 + getMaskedParameter(u_Intensity, outPos)*0.005;
    float xs = xMin + u.y*u.y*(0.5-xMin);

    float s = sign(u.x);
    float absX = abs(u.x)/ratio;
    float x2 = ratio*absX*0.5/xs; //ratio*(absX <= xs ? absX*0.5/xs : (0.5+(absX-xs)*0.5/(1.0-xs)));
    u.x = s*x2;
    vec2 coord = (u_ModelTransform * vec3(u, 1.0)).xy;

    return texture2D(u_Tex0, proj0(coord));

}

#include mainWithOutPos(slim)
