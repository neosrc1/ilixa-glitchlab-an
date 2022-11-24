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

vec4 logist0(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
//    vec2 u = (u_ModelTransform * vec3(0.0, 0.0, 1.0)).xy;
    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    float dx = logistic(fmod((u.x/ratio+1.0)/2.0, 1.0), fmod(u.y+1.0, 2.0)*4.0, 15);

    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);
//    return texture2D(u_Tex0, proj0(pos + vec2(dx, 0.0)));
//    return texture2D(u_Tex0, proj0(pos + vec2(ratio*(2.0*dx-1.0), 0.0)));
    return texture2D(u_Tex0, proj0(vec2(ratio*ratio*(2.0*dx-1.0) * intensity, u.y)));
}

vec4 logist(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
//    vec2 u = (u_ModelTransform * vec3(0.0, 0.0, 1.0)).xy;
    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    float Y = (u.y+1.0)*16.0;
    Y = pow(Y, 0.25);
    float X = fmod((u.x/ratio+1.0)/2.0, 1.0);
    float YY = floor(Y*500.0)/500.0;
    X = floor(X*pow(YY, 5.0))/pow(YY, 5.0);
    float dx = logistic(X, Y, 15);

    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);
//    return texture2D(u_Tex0, proj0(pos + vec2(dx, 0.0)));
//    return texture2D(u_Tex0, proj0(pos + vec2(ratio*(2.0*dx-1.0), 0.0)));
    return texture2D(u_Tex0, proj0(vec2(ratio*ratio*(2.0*dx-1.0) * intensity, u.y)));
}

#include mainWithOutPos(logist)
