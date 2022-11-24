precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform float u_Dampening;
uniform mat3 u_InverseModelTransform;

float dampenSLinear(float x) {
    if (x<0.33333333) {
        return x*x*9.0*0.25;
    }
    else if (x<=0.666666667) {
        return (x*1.5)-0.25;
    }
    else {
        x = 1.0-x;
        x = x*x*9.0*0.25;
        return 1.0-x;
    }
}

vec4 axialBlur(vec2 pos, vec2 outPos) {
//    return texture2D(u_Tex0, proj0(pos));

    float intensity = getMaskedParameter(u_Intensity, outPos);

    vec2 p = (u_InverseModelTransform*vec3(pos, 1.0)).xy;
    if (p.x==0.0 && p.y==0.0) return texture2D(u_Tex0, proj0(pos));

    float dist = length(p);
    float k = 1.0;
    if (dist < 1.0) {
        if (u_Dampening<50.0) {
            float y = 1.0-u_Dampening*0.02;
            k = y + (1.0-y)*dampenSLinear(dist);
        }
        else {
            float x = (u_Dampening-50.0)*0.02;
            if (dist>x) {
                k = dampenSLinear((dist-x)/(1.0-x));
            }
            else {
                k = 0.0;
            }
        }
    }

    vec2 dir = normalize(p);
    float stepLen = 2.0/u_Tex0Dim.y;
    float ratio = (u_Tex0Dim.x/u_Tex0Dim.y);
    vec2 step = dir * stepLen;

    float distance = k * intensity*0.005;
    if (distance <= stepLen) return texture2D(u_Tex0, proj0(pos));
//    return texture2D(u_Tex0, proj0(pos))*1.5;

    float n = 0.0;
    vec4 totalColor = vec4(0.0, 0.0, 0.0, 0.0);
    float maxBack = length(pos - (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy);
    p = pos - min(maxBack, distance*0.5)*dir;
    for(float d=0.0; d<distance; d+=stepLen) {
        totalColor += texture2D(u_Tex0, proj0(p));
        p += step;
        ++n;
    }

    return totalColor / n;

}


#include mainWithOutPos(axialBlur)
