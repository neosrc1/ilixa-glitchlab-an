precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include random

uniform float u_Intensity;
uniform vec4 u_Color1;
uniform float u_Variability;
uniform float u_Count;
uniform float u_Balance;
uniform float u_Power;

vec4 spilloverChannels(vec4 c) {
    float overflow = (max(c.r-1.0, 0.0) + max(c.g-1.0, 0.0) + max(c.b-1.0, 0.0)) / 3.0;
    c.r += overflow;
    c.g += overflow;
    c.b += overflow;
    return c;
}

vec4 alphaAdd(vec4 a, vec4 b) {
    vec4 outc = a + b*b.a;
    outc.a = max(a.a, b.a);
    return outc;
}


vec4 star(vec2 pos, vec2 outPos) {
//    float delta = 0.25 / u_outDim.y;
//    vec2 outPos11 = v_OutCoordinate + vec2(delta, delta);
//    vec2 pos00 = perspective((u_ViewTransform * vec3(outPos00, 1.0)).xy);

    vec4 inc = texture2D(u_Tex0, proj0(pos));

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    float d = length(u);

    vec4 lightC = u_Color1;
    lightC.a = getMaskedParameter(u_Intensity, outPos)*0.01 * lightC.a;

    float kCenter = 0.5*pow(0.01, u_Balance*0.01);
    float kSpikes = 0.0002*pow(0.01, -u_Balance*0.01);
    float k = kCenter/ length(u*10.0);

    float dangle = M_PI*0.5/u_Count;
    for(float i=0.0; i<u_Count; ++i) {
        float ca = cos(i*dangle);
        float sa = sin(i*dangle);
        vec2 v = mat2(ca, sa, -sa, ca)*u;
        float kReduce = i==0.0 ? 1.0 : (fract(2.0*i/u_Count)==0.0 ? 0.1 : 0.01);
        k += kReduce * kSpikes/pow(abs(v.x*v.y), 0.1*u_Power);
    }

    k *= smoothstep(1.0, 0.2, length(u));
    lightC *= k;

    vec4 outc = spilloverChannels(alphaAdd(inc, vec4(lightC.rgb, clamp(lightC.a, 0.0, 1.0))));
    return outc;
}

vec4 starAA(vec2 pos, vec2 outPos) {
        float delta = 0.25 / u_outDim.y;
        vec2 outPos00 = v_OutCoordinate + vec2(-delta, -delta);
        vec2 outPos10 = v_OutCoordinate + vec2(delta, -delta);
        vec2 outPos01 = v_OutCoordinate + vec2(-delta, delta);
        vec2 outPos11 = v_OutCoordinate + vec2(delta, delta);

        vec2 pos00 = (u_ViewTransform * vec3(outPos00, 1.0)).xy;
        vec2 pos10 = (u_ViewTransform * vec3(outPos10, 1.0)).xy;
        vec2 pos01 = (u_ViewTransform * vec3(outPos01, 1.0)).xy;
        vec2 pos11 = (u_ViewTransform * vec3(outPos11, 1.0)).xy;
        return (star(pos00, outPos00) +
            star(pos10, outPos10) +
            star(pos01, outPos01) +
            star(pos11, outPos11) ) * 0.25;
}
#include mainWithOutPos(starAA)
