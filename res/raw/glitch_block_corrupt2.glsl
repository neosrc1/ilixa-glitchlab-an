precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include locuswithcolor
#include random
#include smoothrandom

uniform float u_Mode;
uniform float u_Intensity;
uniform float u_Seed;


float getChannel(int select, vec4 rgb, vec4 hsl) {
    if (select==0) return rgb.r;
    else if (select==1) return rgb.g;
    else if (select==2) return rgb.b;
    else if (select==3) return hsl.r;
    else if (select==4) return hsl.g;
    else return hsl.b;
}

vec4 swap(vec4 rgb, float mode) {
    float coding = floor(mode*0.01*2.0*6.0*6.0*6.0-1.0);
    bool toHsl = coding > 215.0;
    if (toHsl) coding = fmod(coding, 216.0);

    vec4 hsl = RGBtoHSL(rgb);
    hsl.r /= 360.0;
    int rChannel = int(fmod(coding, 6.0));
    int gChannel = int(fmod(coding/6.0, 6.0));
    int bChannel = int(fmod(coding/36.0, 6.0));
    vec4 color = vec4(
        getChannel(rChannel, rgb, hsl) * (toHsl ? 360.0 : 1.0),
        getChannel(gChannel, rgb, hsl),
        getChannel(bChannel, rgb, hsl),
//        getChannel(0, rgb, hsl) * (toHsl ? 360.0 : 1.0),
//        getChannel(1, rgb, hsl),
//        getChannel(2, rgb, hsl),
        rgb.a );

    return toHsl ? HSLtoRGB(color) : color;
}

vec4 mul(vec4 col, float mode) {
    float rMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float gMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float bMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float hMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float sMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float lMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float range = 1.003921568627451;
    vec4 rgb = col;
    rgb.r = fmod(rgb.r*rMul, range);
    rgb.g = fmod(rgb.g*gMul, range);
    rgb.b = fmod(rgb.b*bMul, range);
    vec4 hsl = RGBtoHSL(rgb);
    hsl.x = fmod(hsl.x*hMul, 360.0);
    hsl.y = fmod(hsl.y*hMul, range);
    hsl.z = fmod(hsl.z*hMul, range);
    return HSLtoRGB(hsl);
}

bool inBlockChain(vec2 u, float size) {
//return u.y>0.0;
    float blockWidth = 0.0125;
    float blockHeight = 0.025;
    float index = floor(u.y/blockHeight)*100.0 + floor(u.x/blockWidth);
    return index<=0.0 && index>-size;

//    if (u.y>0.0) return false;
//    if (u.y>-blockHeight && u.x>0.0) return false;
//
//    return true;
}


vec4 offset(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    vec2 rnd = sineSurfaceRand2Seeded(vec2(0.0, 0.0), u_Seed+4.46);
    float size = floor(abs((rnd.x+rnd.y))*5000.0);
    bool inside = inBlockChain(u, size);

//    float mode = (rnd.x+0.5)*100.0;
    float mode = (rnd.x+0.5)*4096.0;
    vec4 inCol = texture2D(u_Tex0, proj0(pos));
//    vec4 outCol = inside ? texture2D(u_Tex0, proj0(-pos)) : inCol;
    vec4 outCol = inside ? swap(inCol, mode) : inCol;
//    vec4 outCol = inside ? mul(inCol, mode) : inCol;
//    return vec4(0.0, 0.0, 0.0, 1.0);

//    float index = recur

    float intensity = 1.0;//getMaskedParameter(u_Intensity, pos) * 0.01;
    intensity *= getLocus(pos, outCol);
    return mix(inCol, outCol, intensity);
}

#include mainWithOutPos(offset)
