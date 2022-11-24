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
    vec2 blockSize = dim/vec2(160.0, 80.0);
    float columns = dim.x/blockSize.x;
    float lines = dim.y/blockSize.y;
    float blocks = columns*lines;
    float index = getIndex(pos, blockSize, dim);

    float offset = u_ModelTransform[2][0]*0.5*columns + u_ModelTransform[2][1]*0.5*lines*columns + 0.5*blocks;
    float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

    for(int i=0; i<u_Count; ++i) {
        vec2 rnd = sineSurfaceRand2Seeded(vec2(10.0-float(i), 15.0+5.0*float(i)), u_Seed+4.46);
        float center = offset + rnd.x*blocks;
        center = fmod(center + blocks, 3.0*blocks) - blocks;
        float bSize = (rnd.x<-0.5+float(i)*0.1)? 0.5 : abs(rnd.y)*blocks*scale;
        float ind1 = center-bSize;
        float ind2 = center+bSize;

        bool inside = (index>=ind1 && index<=ind2);

        int channel = int(fmod(rnd.x*100.0, 3.0));
        vec2 delta = fract(rnd*10.0)*2.0-vec2(1.0, 1.0);
        if (inside) {
            outCol[channel] = texture2D(u_Tex0, proj0(pos+delta))[channel];
        }
    }

    float intensity = getMaskedParameter(u_Intensity, pos) * 0.01;
    intensity *= getLocus(pos, outCol);
    return mix(inCol, outCol, intensity);
}

#include mainWithOutPos(offset)
