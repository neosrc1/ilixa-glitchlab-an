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
    vec2 blockSize = dim / vec2(160.0, 80.0);
    float columns = dim.x/blockSize.x;
    float lines = dim.y/blockSize.y;
    float blocks = columns*lines;
    float index = getIndex(pos, blockSize, dim);

    float offset = u_ModelTransform[2][0]*0.5*columns + u_ModelTransform[2][1]*0.5*lines*columns + 0.5*blocks;
    float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

    float intensity = getMaskedParameter(u_Intensity, pos) * 0.01;

    for(int i=0; i<u_Count; ++i) {
        vec2 rnd = sineSurfaceRand2Seeded(vec2(10.0-float(i), 15.0+5.0*float(i)), u_Seed+4.46);
        float center = offset + rnd.x*blocks;
        float bSize = (rnd.x<-0.5+float(i)*0.1)? 0.5 : abs(rnd.y)*blocks*scale;
        float ind1 = center-bSize;
        float ind2 = center+bSize;

        bool inside = (index>=ind1 && index<=ind2);
        if (inside) {
            float mode = floor(fmod(rnd.x*15.0, 9.0));
            float g = 0.0;
            if (mode==0.0) {
                g = fract(rand2relSeeded(floor(pos*320.0), u_Seed).x) > 0.5 ? 1.0 : 0.0;
            }
            else if (mode==1.0) {
                g = fract(rand2relSeeded(floor(pos*160.0), u_Seed).x) > 0.5 ? 1.0 : 0.0;
            }
            else if (mode==2.0) {
                g = fract(pos.x*40.0)>0.5 ? 1.0 : 0.0;
            }
            else if (mode==3.0) {
                g = fract(pos.x*80.0)>0.5 ? 1.0 : 0.0;
            }
            else if (mode==6.0) {
                g = fract(pos.x*80.0)>length(inCol.rgb)/1.7 ? 1.0 : 0.0;
            }
            else if (mode==7.0) {
                g = fract(pos.x*10.0)<length(inCol.rgb)/1.7 ? 1.0 : 0.0;
            }
            else if (mode==4.0) {
                g = fmod((fract(pos.x*80.0)>0.5 ? 1.0 : 0.0) + (fract(pos.y*40.0)>0.5 ? 1.0 : 0.0), 2.0);
            }
            else if (mode==5.0) {
                g = fract(rand2relSeeded(floor(pos*160.0), u_Seed).x) < length(inCol.rgb)/1.7 ? 1.0 : 0.0;
            }
            else {
                g = fmod((fract(pos.x*40.0)>0.5 ? 1.0 : 0.0) + (fract(pos.y*20.0)>0.5 ? 1.0 : 0.0), 2.0);
            }
            outCol = vec4(g, g, g, 1.0);
            float k = getLocus(pos, outCol);
            return mix(inCol, outCol, k);
        }
    }

    return inCol;
}

#include mainWithOutPos(offset)
