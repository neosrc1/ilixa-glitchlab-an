precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl

uniform float u_SaturationIn;
uniform float u_SaturationOut;
uniform float u_Hue;
uniform float u_Tolerance;
uniform float u_Hardness;

// for values between 0 and 360
float getHueDistance(float h) {
    float d = h-u_Hue;
    if (d < 0.0) d = -d;
    if (d > 180.0) d = 360.0-d;
    return d;
}

float getHueSelectionRatio(float h, float tolerance, float hardness) {
    float hueOutRadius = tolerance*180.0;
    float hueInRadius = hueOutRadius * hardness;

    float hueDistance = getHueDistance(h);
    if (hueDistance <= hueInRadius) {
        return 1.0;
    }
    else if (hueDistance >= hueOutRadius) {
        return 0.0;
    }
    else {
        float d = hueOutRadius-hueInRadius;
        return d==0.0 ? 0.0 : (hueOutRadius-hueInRadius - (hueDistance-hueInRadius)) / d;
    }
}

float getSaturationDampening(float saturation) {
    if (saturation < 0.1) return 0.0;
    else if (saturation >0.3) return 1.0;
    else return (saturation-0.1)*5.0;
}

vec4 bright(vec2 pos) {
    vec4 inc = texture2D(u_Tex0, proj0(pos));

    vec4 hsl = RGBtoHSL(inc);
    float k = getHueSelectionRatio(hsl.x, u_Tolerance*0.01, u_Hardness*0.01);
    float ks = getSaturationDampening(hsl.y);
    float saturation = mix(u_SaturationOut, u_SaturationIn, k*ks) * 0.01;
    hsl.y *= (1.0 + saturation);
    return HSLtoRGB(hsl);
}

#include mainPerPixel(bright)
