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

float getSpikeAngle(vec2 t, float d) {
    float angle = getVecAngle(t, d);

    if (u_Variability != 0.0) {
        float k = angle/M_PI * 20.0;
        angle += u_Variability * 0.02 * interpolatedRand2(vec2(k, 0.0)).x;
    }

    return fmod(angle/M_PI * u_Count + 100.0, 2.0);
}

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

vec4 spotlight(vec2 pos, vec2 outPos) {
    vec4 inc = texture2D(u_Tex0, proj0(pos));

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    float d = length(u);

    float a = getSpikeAngle(u, d);
    a = a <= 1.0 ? a : 2.0-a;

    float r1 = 0.3333;
    float r2 = r1*2.0;
    float r3 = r1*5.0;

    float aa = u_Count>6.0 ? 1.0-(6.0*(1.0-a)/(u_Count)) : a;
//    float dMaxIntensity = r1 + aa*aa*aa*aa*(r3-r1);
//    float dNonZero = dMaxIntensity * 4.0;
    float dNonZero = r3;

    if (d < dNonZero) {
//if (u.x<0) return inc+u_Color1;
        float maxMul = 4.0;
        vec4 lightC = u_Color1;
        lightC.a = getMaskedParameter(u_Intensity, outPos)*0.01;

        float k = (dNonZero-d) / dNonZero * (0.5+0.5*aa*aa);
        lightC *= k * maxMul;


//        if (d < dMaxIntensity) {
//            lightC *= maxMul;
//        }
//        else  {
//            float k = (d-dMaxIntensity) / (dNonZero-dMaxIntensity);
//            lightC *= (1.0-k) * maxMul;
//        }

        vec4 outc = spilloverChannels(alphaAdd(inc, lightC));
        return outc;
    }
    else {
        return inc;
    }

}

#include mainWithOutPos(spotlight)
