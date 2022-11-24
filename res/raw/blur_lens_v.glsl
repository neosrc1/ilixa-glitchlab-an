precision highp float;
precision highp int;

#include commonvar
#include commonfun

uniform float u_Intensity;
uniform float u_Vignetting;
uniform float u_Hardness;

vec4 blurV(vec2 pos, float radius) {
    float pixel = 2.0 / u_Tex0Dim.y;
    int n = int(ceil(radius / pixel))+1;
    vec4 total = vec4(0.0, 0.0, 0.0, 0.0);
    vec2 p = pos - vec2(0.0, float(n)*pixel);
    float div = 0.0;
    for(int j = -n; j<=n; ++j) {
        float d = length(vec2(0.0, float(j))) * pixel / radius;
        if (d<=1.0) {
            float k = (d>0.5) ? (1.0-d)*(1.0-d)*2.0 : 1.0 - d*d*2.0;
            total += k*texture2D(u_Tex0, proj0(p));
            div += k;
        }
        p.y += pixel;
    }
    return total / div;
}

float dampenSLinear(float x, float maxLen) {
    if (x>=1.0-maxLen) return 1.0;
    x = x/(1.0-maxLen);
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

float insideFadingCircle(vec2 pos, mat3 transform) {
    float distance = length((transform*vec3(pos, 1.0)).xy);
    if (distance >= 1.0) return 0.0;
    return dampenSLinear(1.0-distance, u_Hardness*0.01);
}

vec4 blur(vec2 pos, vec2 outPos) {
//    vec4 color = texture2D(u_Tex0, proj0(pos));
    float strength = 1.0 - insideFadingCircle(pos, u_ModelTransform);
    return strength <= 0.0 ? texture2D(u_Tex0, proj0(pos)) : blurV(pos, strength*u_Intensity*0.001);
}

#include mainWithOutPos(blur)
