precision highp float;
precision highp int;

#include commonvar
#include commonfun

uniform float u_Intensity;

//vec4 blurH(vec2 pos, float radius) {
//    float pixel = 2.0 / u_Tex0Dim.y;
//    int n = int(ceil(radius / pixel))+1;
//    vec4 total;
//    vec2 p = pos - vec2(float(n)*pixel, 0.0);
//    float div = 0.0;
//    float pr = pixel/radius;
//    for(int i = -n; i<=n; ++i) {
//        float d = abs(float(i)) * pr;
//        if (d<=1.0) {
//            float k = (d>0.5) ? (1.0-d)*(1.0-d)*2.0 : 1.0 - d*d*2.0;
//            total += k*texture2D(u_Tex0, proj0(p));
//            div += k;
//        }
//        p.x += pixel;
//    }
//    return total / div;
//}
vec4 blurH(vec2 pos, float radius) {
    float pixel = 2.0 / u_Tex0Dim.y;
    int n = int(ceil(radius / pixel))+1;
    if (n<=2) pixel = radius/(float(n)+0.5);
//    if (n<=5) { n=5; pixel = radius/(float(n)+0.5); }
    vec4 total = vec4(0.0, 0.0, 0.0, 0.0);
    vec2 p = pos - vec2(float(n)*pixel, 0.0);
    float div = 0.0;
    float pr = pixel/radius;
    for(int i = -n; i<=n; ++i) {
        float d = abs(float(i)) * pr;
        if (d<=1.0) {
            float k = (d>0.5) ? (1.0-d)*(1.0-d)*2.0 : 1.0 - d*d*2.0;
            total += k*texture2D(u_Tex0, proj0(p));
            div += k;
        }
        p.x += pixel;
    }
    return total / div;
}

vec4 blur(vec2 pos, vec2 outPos) {
    return blurH(pos, u_Intensity*0.005);
}

#include mainWithOutPos(blur)
