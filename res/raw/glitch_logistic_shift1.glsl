precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

//uniform mat3 u_InverseModelTransform;
uniform int u_Count;
uniform float u_Intensity;

float logistic(float x, float lambda, int n) {
    for(int i=0; i<u_Count; ++i) {
        x = lambda*x*(1.0-x);
    }
    return x;
}

vec4 logist(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
//    vec2 u = (u_ModelTransform * vec3(0.0, 0.0, 1.0)).xy;
    float Y = fmod(u.y, 1.0)*4.0;
    if (Y>1.0 && Y<3.5) {
        Y = 1.0 + pow((Y-1.0)/2.5, 12.0)*2.5;
    }
    float dx = logistic(0.5, Y, 15);// - logistic(0.5, fmod(Y*2.2, 4.0), 15);

    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);
    vec2 delta = vec2(ratio*dx * intensity, 0.0);
    delta *= mat2(u_ModelTransform) / length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

    return texture2D(u_Tex0, proj0(pos + delta));
}

#include mainWithOutPos(logist)
