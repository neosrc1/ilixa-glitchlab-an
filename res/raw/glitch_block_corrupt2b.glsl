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
uniform int u_Count;

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
    float blockWidth = 0.0125;//445
    float blockHeight = 0.025;
    float index = floor(u.y/blockHeight)*100.0 + floor(u.x/blockWidth);
    return index<=0.0 && index>-size;

//    if (u.y>0.0) return false;
//    if (u.y>-blockHeight && u.x>0.0) return false;
//
//    return true;
}

float getIndex(vec2 pos, vec2 blockSize, vec2 dim) {
    float columns = dim.x/blockSize.x;
    float lines = dim.y/blockSize.y;
    vec2 f = floor(pos/blockSize);
    return f.x+0.5*columns + (f.y+0.5*lines)*columns;
}

vec4 offset(vec2 pos, vec2 outPos) {
    vec4 inCol = texture2D(u_Tex0, proj0(pos));
    vec4 outCol = inCol;

    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    vec2 dim = vec2(2.0*ratio, 2.0);
    vec2 blockSize = dim / vec2(160.0, 80.0);
    float columns = dim.x/blockSize.x;
    float lines = dim.y/blockSize.y;
    float blocks = columns*lines;
    float index = getIndex(pos, blockSize, dim);

    float offset = u_ModelTransform[2][0]*0.5*columns + u_ModelTransform[2][1]*0.5*lines*columns + 0.5*blocks;
    float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

//    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    for(int i=0; i<u_Count; ++i) {
        vec2 rnd = sineSurfaceRand2Seeded(vec2(10.0-float(i), 15.0+5.0*float(i)), u_Seed+4.46);
//        vec2 rnd = sineSurfaceRand2Seeded(vec2(10.0, 5.0), u_Seed+4.46);
        float center = offset + rnd.x*blocks;
        float bSize = (rnd.x<-0.5+float(i)*0.1)? 0.5 : abs(rnd.y)*blocks*scale;
        float ind1 = center-bSize;
        float ind2 = center+bSize;

//        float size = floor(abs((rnd.x+rnd.y))*5000.0);
    //    bool inside = inBlockChain(u, size);
        bool inside = (index>=ind1 && index<=ind2);

    //    float mode = (rnd.x+0.5)*100.0;
        float mode = (rnd.x+0.5)*4096.0;
    //    outCol = inside ? texture2D(u_Tex0, proj0(-pos)) : inCol;
        outCol = inside ? swap(outCol, mode) : outCol;
    //    outCol = inside ? mul(inCol, mode) : inCol;

    }

    float intensity = getMaskedParameter(u_Intensity, pos) * 0.01;
    intensity *= getLocus(pos, outCol);
    return mix(inCol, outCol, intensity);
}

#include mainWithOutPos(offset)
