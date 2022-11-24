precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

//uniform mat3 u_InverseModelTransform;
uniform int u_Count;
uniform float u_Intensity;
uniform float u_Mode;
uniform float u_Scatter;

float logistic(float x, float lambda, int n) {
    for(int i=0; i<u_Count; ++i) {
        x = lambda*x*(1.0-x);
    }
    return x;
}

vec2 getLogisticCompensated(vec2 u, float intensity) {
    float Y = fmod(u.y, 1.0)*4.0;
    if (Y>1.0 && Y<3.5) {
        Y = 1.0 + pow((Y-1.0)/2.5, 12.0)*2.5;
    }
    float dx = logistic(0.5, Y, 15);// - logistic(0.5, fmod(Y*2.2, 4.0), 15);

    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    vec2 delta = vec2(ratio*dx * intensity, 0.0);
    delta *= mat2(u_ModelTransform) / length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

    return delta;
}

vec2 getLogistic(vec2 u, float intensity) {
    float Y = fmod(u.y, 1.0)*4.0;

    float dx = logistic(0.5, Y, 15) - logistic(0.5, fmod(Y*2.2, 4.0), 15);

    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    vec2 delta = vec2(ratio*dx * intensity, 0.0);
    delta *= mat2(u_ModelTransform) / length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

    return delta;
}

vec2 getMultiSine1(vec2 p, float k) {
    p *= 4.0;
    vec2 delta = 0.3*k*vec2(
        (1.0+sin(0.54*p.y)) * sin(4.0*sin(0.98*p.y)*p.y)
        + (0.5+0.5*cos(1.54*p.y)) * cos(9.0*cos(3.75*p.y)*p.y)
        + (0.25+0.25*cos(3.421*p.y)) * cos(18.0*cos(8.5*p.y)*p.y),
        0.0);
    delta *= mat2(u_ModelTransform) / length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    return 0.5*delta;
}

vec2 getMultiSine2(vec2 p, float k) {
    float z = fract(p.y*0.13123+565.444);
    z = fract(z*z*412.55);
    z = pow(abs(z*2.0-1.0), 4.0);
    float y = p.y;
    vec2 delta = z*k*vec2(
        (1.0+sin(0.4*y)) * sin(4.0*sin(0.98*y)*y)
        + (0.3+0.3*cos(1.54*y)) * cos(9.0*cos(3.75*y)*y),
        0.0);
    delta *= mat2(u_ModelTransform) / length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    return 0.5*delta;
}

float getRand(float x) {
    return (2.0*fract((fract(x*123.237+10.4343)+23.773)*434.4438))-1.0;
}

float get2Rand(vec2 u) {
    return (2.0*fract((fract(u.x*123.237+10.4343+u.y)+23.773+10.565*u.y-u.x)*434.4438))-1.0;
}

vec4 getRand4(vec4 v) {
    return vec4(getRand(v.x), getRand(v.y), getRand(v.z), getRand(v.w));
}

vec2 getPerlin(vec2 p, float power, float k) {
    p *= 10.0;
    float delta = 0.0;
    float scale = 0.5;
    for(int i=0; i<10; ++i) {
        float p0 = floor(p.y);
        float p1 = ceil(p.y);
        float f = fract(p.y);
        delta += mix(getRand(p0), getRand(p1), smoothstep(0.0, 1.0, f)) * scale;
        scale *= 0.5;
        p = p*2.0;
    }
    return mat2(u_ModelTransform) / length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]))
        * vec2(delta * pow(clamp(0.0, 1.0, abs(delta)*1.3), power-1.0) * k, 0.0);
}

vec2 getHighVariance(vec2 p, float threshold, float k) {
    p *= 10.0;
    float Y = p.y;
    float delta = 0.0;
    float scale = 0.5;
    for(int i=0; i<10; ++i) {
        float p0 = floor(p.y);
        float p1 = ceil(p.y);
        float f = fract(p.y);
        delta += mix(getRand(p0), getRand(p1), smoothstep(0.0, 1.0, f)) * scale;
        scale *= 0.5;
        p = p*2.0;
    }
    float l = smoothstep(threshold-0.2, threshold+0.2, delta);
    delta = l* sin(Y*100.0);

    return mat2(u_ModelTransform) / length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]))
        * vec2(delta * k, 0.0);
}

vec2 getPerlinSine(vec2 p, float threshold, float k) {
    p *= 15.0;
    float Y = p.y;
    vec4 delta = vec4(0.0);
    float scale = 0.5;
    for(int i=0; i<10; ++i) {
        float p0 = floor(p.y);
        float p1 = ceil(p.y);
        float f = fract(p.y);
        delta += mix(getRand4(vec4(p0, p0+5.0, p0+50.0, p0+123.0)), getRand4(vec4(p1, p1+5.0, p1+50.0, p1+123.0)), smoothstep(0.0, 1.0, f)) * scale;
        scale *= 0.5;
        p = p*2.0;
    }
    //float d = delta * pow(clamp(0.0, 1.0, abs(delta)*1.3), power-1.0) * k;
//    float A = smoothstep(-0.125, -1.0, delta.y);
//    float B = smoothstep(0.25, 1.0, delta.w);
    float A = smoothstep(-1.0+threshold, -1.0, delta.z*delta.y);
    float B = smoothstep(1.0-threshold, 1.0, delta.w*delta.x);
    float s = A*delta.x*sin(Y*(0.5+0.125*delta.y)) + B*delta.z*sin(Y*(6.0+2.0*delta.w));
    //float s = A*delta.x*sin(Y*(0.5+0.125*delta.y)) + B*pow(clamp(0.0, 1.0, abs(delta.z)*1.3), power-1.0)*sin(Y*(6.0+2.0*delta.w));
    return mat2(u_ModelTransform) / length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]))
        * vec2(s*k*10.0, 0.0);
}

vec2 getDelta(vec2 u, float intensity) {
    float modeCount = 11.0;
    float scaledMode = u_Mode*0.01*(modeCount-1.0);
    float fractMode = fract(scaledMode);
    float lowMode = floor(scaledMode);
    float highwMode = ceil(scaledMode);
    if (lowMode==0.0) {
        return mix(getLogistic(u, intensity), getMultiSine2(u, intensity), fractMode);
    }
    else if (lowMode==1.0) {
        return mix(getMultiSine2(u, intensity), getLogisticCompensated(u, intensity), fractMode);
    }
    else if (lowMode==2.0) {
        return mix(getLogisticCompensated(u, intensity), getMultiSine1(u, intensity), fractMode);
    }
    else if (lowMode==3.0) {
        return mix(getMultiSine1(u, intensity), getPerlin(u, 1.0, intensity), fractMode);
    }
    else if (lowMode==4.0) {
        return getPerlin(u, mix(1.0, 5.0, fractMode), intensity);
        //return mix(getPerlin(u, 1.0, intensity), getPerlin(u, 5.0, intensity), fractMode);
    }
    else if (lowMode==5.0) {
        //return getPerlin(u, mix(1.0, 5.0, fractMode), intensity);
        return mix(getPerlin(u, 5.0, intensity), getPerlin(u, 2.0, intensity*0.1), fractMode);
    }
//    else if (lowMode==6.0) {
//        //return getPerlin(u, mix(1.0, 5.0, fractMode), intensity);
//        return getPerlin(u, mix(2.0, 1.0, fractMode), mix(0.1, 1.0, fractMode)*intensity);
//    }
    else if (lowMode==6.0) {
        //return getPerlin(u, mix(1.0, 5.0, fractMode), intensity);
        return mix(getPerlin(u, 2.0, intensity*0.1), getPerlinSine(u, 1.0, 1.0), fractMode);
    }
    else if (lowMode==7.0) {
        //return getPerlin(u, mix(1.0, 5.0, fractMode), intensity);
        return getPerlinSine(u, mix(1.0, 5.0, fractMode), intensity*mix(1.0, 0.1, fractMode));
    }
    else if (lowMode==8.0) {
        //return getPerlin(u, mix(1.0, 5.0, fractMode), intensity);
        return mix(getPerlinSine(u, 5.0, intensity*0.1), getHighVariance(u, -0.5, intensity), fractMode);
    }
    else if (lowMode==9.0) {
        //return getPerlin(u, mix(1.0, 5.0, fractMode), intensity);
        return getHighVariance(u, mix(-0.5, 0.5, fractMode), intensity);
    }
    else {
        return getHighVariance(u, 0.5, intensity);
    }
}

vec4 shift(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
//    vec2 u = (u_ModelTransform * vec3(0.0, 0.0, 1.0)).xy;
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);
    vec2 delta = getDelta(u, intensity);

    float scatter = u_Scatter * 0.02;
    if (scatter>0.0) {
        float scattering = smoothstep(1.0-scatter, 1.0-scatter*0.5, 0.5+0.5*sin(u.y*5.0));
//        if (abs(sin(u.y*10.0))<scatter) {
            float k = mix(1.0, abs(rand2rel(u).x), scattering);
            delta = k*delta;
//        }
    }
    return texture2D(u_Tex0, proj0(pos + delta));
}

#include mainWithOutPos(shift)
