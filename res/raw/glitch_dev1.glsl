precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include locus

uniform float u_Intensity;
uniform float u_Phase;

//vec4 offset(vec2 pos, vec2 outPos) {
//    float intensity = u_Intensity * getLocus(pos);
//    int N = int(abs(intensity)*u_Tex0Dim.y*0.005); //int(u_Intensity*0.01 * (1.0-length(inc.xyz)));
//    float delta = 1.0/u_Tex0Dim.y * sign(intensity);
//    vec2 d = vec2(delta, 0.0);
//    vec2 p = pos;
//    vec4 c = texture2D(u_Tex0, proj0(p));
//    for(int i=0; i<N; ++i) {
//        vec4 c1 = texture2D(u_Tex0, proj0(p+d));
//        vec4 c2 = texture2D(u_Tex0, proj0(p-d));
//        vec4 c3 = texture2D(u_Tex0, proj0(p+d.yx));
//        vec4 c4 = texture2D(u_Tex0, proj0(p-d.yx));
//        float d1 = length(c-c1);
//        float d2 = length(c-c2);
//        float d3 = length(c-c3);
//        float d4 = length(c-c4);
////        if (d1<d2 && d1<d3 && d1<d4) {
////            p += d;
////            c = c1;
////        }
////        else if (d2<d3 && d2<d4) {
////            p -= d;
////            c = c2;
////        }
////        else if (d3<d4) {
////            p += d.yx;
////            c = c3;
////        }
////        else {
////            p -= d.yx;
////            c = c4;
////        }
//        if (d1>d2 && d1>d3 && d1>d4) {
//            p += d;
//            c = c1;
//        }
//        else if (d2>d3 && d2>d4) {
//            p -= d;
//            c = c2;
//        }
//        else if (d3>d4) {
//            p += d.yx;
//            c = c3;
//        }
//        else {
//            p -= d.yx;
//            c = c4;
//        }
//
//    }
//    vec4 outCol = c;
//    return outCol;
//}

//vec4 offset(vec2 pos, vec2 outPos) {
//    float intensity = u_Intensity * getLocus(pos);
//    int N = int(abs(intensity)*u_Tex0Dim.y*0.005); //int(u_Intensity*0.01 * (1.0-length(inc.xyz)));
//    float delta = 1.0/u_Tex0Dim.y * sign(intensity);
//    float phase = u_Phase;
//    vec2 disp = delta * vec2(cos(phase), sin(phase));
//    vec2 bigDisp = 50.0 * disp;
//    float energy = 0.0;
//    for(int i=0; i<N; ++i) {
//        vec4 inc = texture2D(u_Tex0, proj0(pos));
//        energy += length(inc.rgb);
//
//        vec2 step = (energy>10.0) ? bigDisp : disp;
//        if (energy>10.0) energy = 0.0;
//
//        if (max(abs(inc.r-inc.g), abs(inc.r-inc.b))<0.01) {
//            pos -= step;
//            phase += M_PI/4.0;
//            disp = delta * vec2(cos(phase), sin(phase));
//            bigDisp = 50.0 * disp;
//        }
//        if (inc.r>inc.g && inc.r>inc.b) {
//            pos += step;
//        }
//        else if (inc.g>inc.b) {
//            pos += step.yx;
//            phase -= M_PI/4.0;
//            disp = delta * vec2(cos(phase), sin(phase));
//            bigDisp = 50.0 * disp;
//        }
//        else {
//            pos -= step.yx;
//        }
//
//    }
//    vec4 outCol = texture2D(u_Tex0, proj0(pos));
//    return outCol;
//}


vec4 offset(vec2 pos, vec2 outPos) {
    float intensity = u_Intensity * getLocus(pos);
    float delta = 0.001;// 1.0/u_Tex0Dim.y;
    vec2 d = vec2(delta, 0.0);
//    int N = int(abs(intensity)*u_Tex0Dim.y*0.005); //int(u_Intensity*0.01 * (1.0-length(inc.xyz)));
    int N = int(abs(intensity)*1.0); //int(u_Intensity*0.01 * (1.0-length(inc.xyz)));
    vec4 c;
    for(int i=0; i<N; ++i) {
        vec4 c1 = texture2D(u_Tex0, proj0(pos+d));
        vec4 c2 = texture2D(u_Tex0, proj0(pos-d));
        vec4 c3 = texture2D(u_Tex0, proj0(pos+d.yx));
        vec4 c4 = texture2D(u_Tex0, proj0(pos-d.yx));
        c = texture2D(u_Tex0, proj0(pos));

        vec4 hsl = HSLtoRGB((c+c1+c2+c3+c4)/5.0);
        float k = 1.0-2.0*abs(0.5-hsl.z);
        float magnitude = hsl.z + k*hsl.x/360.0; // -1 to 2
        float angle = u_Phase + floor(fmod(magnitude, 3.0)*8.0/3.0)/4.0*M_PI;
        pos += sign(intensity) * (50.0*hsl.z+0.5)*delta*vec2(cos(angle), sin(angle));
    }
    return texture2D(u_Tex0, proj0(pos));
}
#include mainWithOutPos(offset)
