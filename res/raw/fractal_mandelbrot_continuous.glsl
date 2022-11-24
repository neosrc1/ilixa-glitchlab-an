precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include perspective

uniform vec2 u_Offset;
uniform int u_Iterations;
uniform int u_Count;
uniform float u_Intensity;
uniform float u_Power;
uniform float u_Julianess;

//vec4 mandelbrotOld(vec2 pos, vec2 outPos) {
//
//    vec2 t = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;
//
//    vec2 z = u_Offset;
//
//    vec2 prev = t;
//
//    int iter = 0;
//    float d2 = 0.0;
//
//    float intensity = getMaskedParameter(u_Intensity, outPos);
//
//    while (iter < u_Iterations) {
//        ++iter;
//        prev = z;
//        z.x = prev.x*prev.x - prev.y*prev.y + t.x;
//        z.y = 2.0*prev.x*prev.y + t.y;
//
////        z.x = prev.x*prev.x*prev.x - 3.0*prev.y*prev.y*prev.x + t.x;
////        z.y = -prev.y*prev.y*prev.y + 3.0*prev.x*prev.x*prev.y + t.y;
//
//        float len = length(z);
////        if (len>2.0) z /= sqrt(len-1.0);
////        if (len>2.0) z = (z + (len-2.0)*t)/(len-1.0); // microchip
////        if (len>2.0) { float k = (len-2.0)*(len-2.0); z = (z + k*t)/(k+1.0); } // cool overlaping features
////        float k = len*len; z = (z + k*t)/(k+1.0); // not fractal but interesting
//        float p = intensity*intensity*intensity*intensity*intensity * (4.0/pow(50.0, 5.0)); float k = len*len*p; z = (z + k*t)/(k+1.0);
//    }
//
////    float len = length(z);
////    if (len>0.0) z /= len;
//
//    return texture2D(u_Tex0, proj0(z));
//
//}

vec4 mandelbrot(vec2 pos, vec2 outPos) {

    float cj = cos(u_Julianess * M_PI*0.005);
    float sj = sin(u_Julianess * M_PI*0.005);

    vec2 t = (u_ModelTransform * vec3(cj * perspective(pos), 1.0)).xy;

    vec2 z = (mat2(u_ModelTransform) * (sj * perspective(pos))) + u_Offset;

    vec2 prev = t;

    int iter = 0;
    float d2 = 0.0;

    float intensity = getMaskedParameter(u_Intensity, outPos);
    float p = intensity*intensity*intensity*intensity*intensity * (4.0/pow(50.0, 5.0));

        if (u_Power == 2.0) {
        while (iter < u_Iterations) {
            ++iter;
            prev = z;
            z.x = prev.x*prev.x - prev.y*prev.y + t.x;
            z.y = 2.0*prev.x*prev.y + t.y;
            float len = length(z);
    //        if (len>2.0) z /= sqrt(len-1.0);
    //        if (len>2.0) z = (z + (len-2.0)*t)/(len-1.0); // microchip
    //        if (len>2.0) { float k = (len-2.0)*(len-2.0); z = (z + k*t)/(k+1.0); } // cool overlaping features
    //        float k = len*len; z = (z + k*t)/(k+1.0); // not fractal but interesting
            float k = len*len*p;
            z = (z + k*t)/(k+1.0);
        }
    }
    else if (u_Power == 3.0) {
        while (iter < u_Iterations) {
            ++iter;
            prev = z;
            z.x = prev.x*prev.x*prev.x - 3.0*prev.y*prev.y*prev.x + t.x;
            z.y = -prev.y*prev.y*prev.y + 3.0*prev.x*prev.x*prev.y + t.y;
            float len = length(z);
            float k = len*len*p;
            z = (z + k*t)/(k+1.0);
        }
    }
    else {
        float d = length(z);

        while (iter < u_Iterations) {
            ++iter;
            prev = z;
            float angle = getVecAngle(prev, d);
            //if (angle<0.0) angle+=M_2PI;

            float dp = pow(d, u_Power);
            z.x = dp*cos(u_Power*angle) + t.x;
            z.y = dp*sin(u_Power*angle) + t.y;

            float len = length(z);
            float k = len*len*p;
            z = (z + k*t)/(k+1.0);
            d = len;
        }

    }

//    if (isnan(z.x) || isinf(z.x) || isnan(z.y) || isinf(z.y)) return vec4(0.0, 0.0, 0.0, 1.0);
//    if (isinf(z.x)|| isinf(z.y)) return vec4(0.0, 0.0, 0.0, 1.0);

//    float len = length(z);
//    if (len>0.0) z /= len;

    return texture2D(u_Tex0, proj0(z));

}




#include mainWithOutPos(mandelbrot)
