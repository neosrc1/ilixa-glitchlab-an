precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include hsl
#include locus8

uniform int u_Count;
uniform float u_Intensity;
uniform float u_Balance;
uniform float u_Regularity;
uniform float u_Power;
uniform float u_Mode;
uniform float u_Seed;

vec2 f2(vec2 u, vec2 split, vec2 s, float intensity) {
    float mode = u_Mode;
	float mul = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
    vec2 rnd = rand2relSeeded(s, u_Seed);
//    float type1 = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
//    float type2 = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
//    float type3 = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
//    float type4 = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);

        float type1 = 0.0;
        float type2 = 1.0;
        float type3 = 2.0;
        float type4 = 3.0;

//    float type1 = fmod(rnd.x*10.0, 4.0);
//    float type2 = fmod(rnd.x*1000.0, 4.0);
//    float type3 = fmod(rnd.x*10.0, 4.0);
//    float type4 = fmod(rnd.y*1000.0, 4.0);

    int N = u_Count;
    for(int i=0; i<N; ++i) {
        float type;
        if (u.x>split.x && u.y>split.y) {
            type = type1;
        }
        else if (u.x<=split.x && u.y>split.y) {
            type = type2;
        }
        else if (u.x>split.x) {
            type = type3;
        }
        else {
            type = type4;
        }

        if (type==0.0) {
            u *= 1.0+rnd.x;
            //u.x += 0.02*u.y;
        }
        else if (type==1.0) {
            float ox = u.x;
            u.x = sign(rnd.x)*u.y;
            u.y = sign(rnd.y)*ox;
        }
        else if (type==2.0) {
            u.x += rnd.y*2.0;
        }
        else if (type==3.0) {
            u.x = fmod(sign(u.x)*pow(abs(u.x), rnd.y), 1.0);
            u.y = fmod(sign(u.y)*pow(abs(u.y), rnd.x), 1.0);

            // slightly different alternative, also good
//            u.x = sign(u.x)*pow(abs(u.x), rnd.y);
//            u.y = sign(u.y)*pow(abs(u.y), rnd.x);
//            u = fract((u+1.0)/2.0)*2.0-1.0;

            //            u.x = pow(u.x, rnd.y);// old style: not working on Tab S2
            //            u.y = pow(u.y, rnd.x);

//            if (u_Balance<1.0) {
//                u.x = fmod(sign(u.x)*pow(abs(u.x), rnd.y), 1.0);// not working on Tab S2
//                u.y = fmod(sign(u.y)*pow(abs(u.y), rnd.x), 1.0);
//            }
//            else {
//                u.x = sign(u.x)*pow(abs(u.x), rnd.y);// not working on Tab S2
//                u.y = sign(u.y)*pow(abs(u.y), rnd.x);
//                u = fract((u+1.0)/2.0)*2.0-1.0;
//            }
        }

        if (max(abs(u.x), abs(u.y))>1.5) {
            u *= pow(2.0, intensity);
        }

    }
    return u;
}
/*
vec2 f3(vec2 u, vec2 split, vec2 s, float intensity, mat3 t) {
    float mode = u_Mode;
	float mul = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
//    float type1 = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
//    float type2 = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
//    float type3 = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
//    float type4 = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
    float type1 = 0.0;
    float type2 = 1.0;
    float type3 = 2.0;
    float type4 = 3.0;

    int N = u_Count;
    vec2 rnd = rand2relSeeded(s, u_Seed);
    for(int i=0; i<N; ++i) {
        float type;
        if (u.x>split.x && u.y>split.y) {
            type = type1;
        }
        else if (u.x<=split.x && u.y>split.y) {
            type = type2;
        }
        else if (u.x>split.x) {
            type = type3;
        }
        else {
            type = type4;
        }

        if (type==0.0) {
            u *= 1.0+rnd.x;
            //u.x += 0.02*u.y;
        }
        else if (type==1.0) {
            float ox = u.x;
            u.x = sign(rnd.x)*u.y;
            u.y = sign(rnd.y)*ox;
        }
        else if (type==2.0) {
            u.x += rnd.y*2.0;
        }
        else if (type==3.0) {
            u.x = fmod(sign(u.x)*pow(abs(u.x), rnd.y), 1.0);
            u.y = fmod(sign(u.y)*pow(abs(u.y), rnd.x), 1.0);
        }

        if (max(abs(u.x), abs(u.y))>1.5) {
            u *= pow(2.0, intensity);
        }

        split = (t*vec3(split, 1.0)).xy;
        if (abs(split.x)>1.0) split.x = fract((split.x+1.0)/2.0)*2.0-1.0;
        if (abs(split.y)>1.0) split.y = fract((split.y+1.0)/2.0)*2.0-1.0;
    }
    return u;
}*/
vec4 breakg6(vec2 pos, vec2 outPos) {
    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    vec2 vRatio = vec2(ratio, 1.0);
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);
    float balance = u_Balance;//pow(2.0, u_Balance*0.15);

    vec2 u1 = (u_ModelTransform * vec3(pos, 1.0)).xy;
    vec2 split1 = fract(u1)*2.0-1.0;

    vec4 col = texture2D(u_Tex0, proj0(pos));
    float power = u_Power*0.01;
    vec2 px = f2(pos/vRatio, split1, floor(u1), power)*vRatio;
    vec2 py = f2(pos/vRatio, split1, floor(u1)-vec2(1.0, 1.0), power)*vRatio;
    vec2 pz = f2(pos/vRatio, split1, floor(u1)+vec2(2.0, 0.0), power)*vRatio;

    //    mat3 identity = mat3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
//    mat3 ttt = mat3(mix(identity[0], u_ModelTransform[0], u_Regularity*0.01), mix(identity[1], u_ModelTransform[1], u_Regularity*0.01), mix(identity[2], u_ModelTransform[2], u_Regularity*0.01));
//    vec2 px = f3(pos/vRatio, split1, floor(u1), u_Power*0.01, ttt)*vRatio;
//    vec2 py = f3(pos/vRatio, split1, floor(u1)-vec2(1.0, 1.0), u_Power*0.01, ttt)*vRatio;
//    vec2 pz = f3(pos/vRatio, split1, floor(u1)+vec2(2.0, 0.0), u_Power*0.01, ttt)*vRatio;
    vec4 outCol;

    float mode = u_Mode;
    bool fixedBkg = floor(fmod(mode, 2.0))==0.0; mode = floor(mode/2.0);
    float tN = 16.0;
	//float mul = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
    float type1 = floor(fmod(mode, tN)); mode = floor(mode/tN);
    float type2 = floor(fmod(mode, tN)); mode = floor(mode/tN);
    float type3 = floor(fmod(mode, tN)); mode = floor(mode/tN);
    float type = 0.0;

//    if (balance<1.0) balance = 1.0/balance;

    if (length(px-py) > length(py-pz)*balance && balance<100.0) {
        type = 0.0; // do nothing
    }
    else if (length(px-py) > length(px-pz)) {
        type = type1;
    }
    else if (length(py-pz) > length(py-px)) {
        type = type2;
    }
    else {
        type = type3;
    }

    if (type==0.0) {
        outCol = texture2D(u_Tex0, proj0(fixedBkg ? outPos : pos));
    }
    else if (type==1.0) { //hor. gradient
        vec4 a = texture2D(u_Tex0, proj0(vec2(-0.99*ratio, px.y)));
        vec4 b = texture2D(u_Tex0, proj0(vec2(0.99*ratio, px.y)));
        outCol = mix(a, b, fract((px.x+1.0)/2.0));
    }
    else if (type==2.0) { //vert. gradient
        vec4 a = texture2D(u_Tex0, proj0(vec2(px.x, -0.99)));
        vec4 b = texture2D(u_Tex0, proj0(vec2(px.x, 0.99)));
        outCol = mix(a, b, fract((px.y+1.0)/2.0));
    }
    else if (type==3.0) { // rgb split
        vec2 step = normalize(px-py)*intensity*0.2;
        float r = texture2D(u_Tex0, proj0(pos-step)).r;
        float g = texture2D(u_Tex0, proj0(pos)).g;
        float b = texture2D(u_Tex0, proj0(pos+step)).b;
        outCol = vec4(r, g, b, col.a);
    }
    else if (type==4.0) { // greyscale
        outCol = texture2D(u_Tex0, proj0(pos));
        float g = pow((outCol.r + outCol.g + outCol.b)/3.0, intensity+1.0);
        outCol = vec4(g, g, g, col.a);
    }
    else if (type==5.0) { // b&w pixelated
        float s = 40.0*intensity;
        outCol = texture2D(u_Tex0, proj0(floor(px*s)/s));
        float g = floor((outCol.r + outCol.g + outCol.b)/3.0+0.5);
        outCol = vec4(g, g, g, col.a);
    }
    else if (type==6.0) { // 8 color pixelated
        float s = 40.0*intensity;
        outCol = floor(texture2D(u_Tex0, proj0(floor(px*s)/s)) + 0.5);
    }
    else if (type==7.0) { // geom distortion
//        outCol = texture2D(u_Tex0, proj0(vec2(0.0, px.y)));
//        outCol = texture2D(u_Tex0, proj0(mix(vec2(0.0, px.y), outPos, fract(pos.x))));
//        outCol = texture2D(u_Tex0, proj0(mix(vec2(0.0, fract((px.y+1.0)/2.0)*2.0-1.0), fixedBkg ? outPos : pos, mix(fract(pos.x), 1.0, intensity))));
        outCol = texture2D(u_Tex0, proj0(mix(fixedBkg ? outPos : pos, vec2(0.0, fract((px.y+1.0)/2.0)*2.0-1.0), fract(pos.x)*intensity)));
    }
    else if (type==8.0) {// geom distortion
//        outCol = texture2D(u_Tex0, proj0(vec2(px.x, 0.0)));
//        outCol = texture2D(u_Tex0, proj0(mix(vec2(px.x, 0.0), fixedBkg ? outPos : pos, mix(fract(px.y), 1.0, intensity))));
        outCol = texture2D(u_Tex0, proj0(mix(fixedBkg ? outPos : pos, vec2(px.x, 0.0), fract(px.y)*intensity)));
    }
    else if (type==9.0) { // rgb split
        float r = texture2D(u_Tex0, proj0(mix(pos, px, intensity-0.5))).r;
        float g = texture2D(u_Tex0, proj0(py)).g;
        float b = texture2D(u_Tex0, proj0(pz)).b;
        outCol = vec4(r, g, b, col.a);
    }
    else if (type==10.0) { // hue gradient hor.
        vec4 a = RGBtoHSL(texture2D(u_Tex0, proj0(vec2(-0.5*ratio, px.y))));
        vec4 b = RGBtoHSL(texture2D(u_Tex0, proj0(vec2(0.5*ratio, px.y))));
        float l = abs(a.z-0.5)<abs(b.z-0.5) ? a.z : b.z;
//        vec4 hsl = vec4(mix(a.x*(1.0+intensity), b.x*(1.0+intensity), fract((px.x+1.0)/2.0)), max(a.y, b.y), l, max(a.a, b.a));
//        vec4 hsl = vec4(mix(a.x, b.x, fract((px.x+1.0)/2.0)), 1.0, 0.5, max(a.a, b.a));
        float km = (1.0+intensity)/2.0;
        vec4 hsl = vec4(mix(mix(0.0, a.x, km), mix(360.0, b.x, km), fract((px.x+1.0)/2.0)), 1.0, l, max(a.a, b.a));
        outCol = HSLtoRGB(hsl);
    }
    else if (type==11.0) { // hue gradient vert.
        vec4 a = RGBtoHSL(texture2D(u_Tex0, proj0(vec2(px.x, -0.5))));
        vec4 b = RGBtoHSL(texture2D(u_Tex0, proj0(vec2(px.x, 0.5))));
        float l = abs(a.z-0.5)<abs(b.z-0.5) ? a.z : b.z;
//        vec4 hsl = vec4(mix(a.x*(1.0+intensity), b.x*(1.0+intensity), fract((px.y+1.0)/2.0)), max(a.y, b.y), l, max(a.a, b.a));
        float km = (1.0+intensity)/2.0;
        vec4 hsl = vec4(mix(mix(0.0, a.x, km), mix(360.0, b.x, km), fract((px.y+1.0)/2.0)), 1.0, l, max(a.a, b.a));
//        vec4 hsl = vec4(mix(a.x*(1.0+intensity), b.x*(1.0+intensity), fract((px.y+1.0)/2.0)), 1.0, 0.5, max(a.a, b.a));
        outCol = HSLtoRGB(hsl);
    }
    else if (type==12.0) { // greyscale gradient hor.
        vec4 a = RGBtoHSL(texture2D(u_Tex0, proj0(vec2(-0.5*ratio, px.y))));
        vec4 b = RGBtoHSL(texture2D(u_Tex0, proj0(vec2(0.5*ratio, px.y))));
        float km = (1.0+intensity)/2.0;
        vec4 hsl = vec4(0.0, 0.0, mix(mix(0.0, a.z, km), mix(1.0, b.z, km), fract((px.x+1.0)/2.0)), max(a.a, b.a));
        outCol = HSLtoRGB(hsl);
    }
    else if (type==13.0) { // b&w banded
        float s = 40.0*intensity;
        outCol = texture2D(u_Tex0, proj0(px));
        float g = floor((outCol.r + outCol.g + outCol.b)/3.0 + (fract(px.x*40.0)-0.5)*intensity + 0.5);
        outCol = vec4(g, g, g, col.a);
    }
    else {
        outCol = texture2D(u_Tex0, proj0(pos));
    }

    float k = getLocus(outPos, col, outCol);
    if (k==1.0) return outCol;
    else return mix(texture2D(u_Tex0, proj0(outPos)), outCol, k);
}


#include mainWithOutPos(breakg6)
