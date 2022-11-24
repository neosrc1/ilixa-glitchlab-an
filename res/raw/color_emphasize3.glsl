precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include color

uniform float u_Intensity;
uniform float u_Saturation;
uniform float u_Tolerance;
uniform float u_Separation;
uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform vec4 u_Color3;

vec4 emphasize(vec2 pos) {
    vec4 inc = texture2D(u_Tex0, proj0(pos));

    vec4 inHsl = RGBtoHSL(inc);
    vec4 emp1Hsl = RGBtoHSL(u_Color1);
    vec4 emp2Hsl = RGBtoHSL(u_Color2);
    vec4 emp3Hsl = RGBtoHSL(u_Color3);
    vec2 delta1 = vec2((inHsl.x-emp1Hsl.x)/180.0, inHsl.y-emp1Hsl.y);
    vec2 delta2 = vec2((inHsl.x-emp2Hsl.x)/180.0, inHsl.y-emp2Hsl.y);
    vec2 delta3 = vec2((inHsl.x-emp3Hsl.x)/180.0, inHsl.y-emp3Hsl.y);
    if (delta1.x>1.0) delta1.x = 2.0-delta1.x;
    if (delta2.x>1.0) delta2.x = 2.0-delta2.x;
    if (delta3.x>1.0) delta3.x = 2.0-delta3.x;
//    float dist1 = length(delta1);
//    float dist2 = length(delta2);
//    float dist3 = length(delta3);
    float dist1 = length((inc-u_Color1).rgb);
    float dist2 = length((inc-u_Color2).rgb);
    float dist3 = length((inc-u_Color3).rgb);

    float tolerance = u_Tolerance*0.0174;
    if (dist1 >= tolerance && dist2 >= tolerance && dist3 >= tolerance) return inc;
    vec4 rgb1, rgb2, rgb3;
    float dist;

    float separation = 0.0 + u_Separation*0.1;

    float intensity = getMaskedParameter(u_Intensity, pos)*0.01;
    float k0 = 1.0;
    float k1 = 0.0;
    float k2 = 0.0;
    float k3 = 0.0;
    if (dist1 < tolerance) {
        k1 = 1.0-dist1/tolerance;
        k0 = max(0.0, k0-k1);
        rgb1 = colorize(inc, u_Color1, u_Saturation*0.01);
    }
    if (dist2 < tolerance) {
        k2 = 1.0-dist2/tolerance;
        k0 = max(0.0, k0-k2);
        rgb2 = colorize(inc, u_Color2, u_Saturation*0.01);
    }
    if (dist3 < tolerance)  {
        k3 = 1.0-dist3/tolerance;
        k0 = max(0.0, k0-k3);
        rgb3 = colorize(inc, u_Color3, u_Saturation*0.01);
    }

    if (separation==0.0) {
        k0 = k1 = k2 = k3 = 1.0;
    }
    else {
        k1 = pow(k1, separation);
        k2 = pow(k2, separation);
        k3 = pow(k3, separation);
        k0 = pow(k0, separation);
    }

    vec4 rgb = (inc*k0 + rgb1*k1 + rgb2*k2 + rgb3*k3) / (k0+k1+k2+k3);
    return mix(inc, rgb, intensity);


//    vec4 rgb1, rgb2, rgb3;
//    float dist;
//    if (dist1 < tolerance) {
//        dist = dist1;
//        rgb1 = colorize(inc, u_Color1, u_Saturation*0.01);
//    }
//    else if (dist2 < tolerance) {
//        dist = dist2;
//        rgb2 = colorize(inc, u_Color2, u_Saturation*0.01);
//    }
//    else {
//        dist = dist3;
//        rgb3 = colorize(inc, u_Color3, u_Saturation*0.01);
//    }
//
//    float intensity = getMaskedParameter(u_Intensity, pos)*0.01 * (1.0-dist/tolerance);
//    return mix(inc, rgb, intensity);

}

#include mainPerPixel(emphasize)
