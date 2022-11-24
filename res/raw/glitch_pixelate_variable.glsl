precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include locuswithcolor_nodep

uniform sampler2D u_Palette;
uniform float u_Regularity;
uniform float u_Balance;
uniform int u_ColorCount;
uniform float u_Dither[16];
uniform int u_DitherWidth;
uniform int u_DitherHeight;
uniform float u_Dithering;

vec4 getFromPalette(vec4 color) {
    if (u_ColorCount<=1) return color;

    float closestDist = 10000000.0;
    vec4 closestColor;
    for(int i=0; i<u_ColorCount; ++i) {
        float x = (0.5 + float(i))/float(u_ColorCount);
        vec4 c = texture2D(u_Palette, vec2(x, 0.0));
        float dist = length(color-c);
        if (dist < closestDist) {
            closestColor = c;
            closestDist = dist;
        }
    }

    return closestColor;
}

float getAvgDistance(vec4 color, vec2 u, float scale) {
    float total = 0.0;
    for(int j=-1; j<=1; ++j) {
        for(int i=-1; i<=1; ++i) {
            vec4 other = texture2D(u_Tex0, proj0(u + scale*0.5*vec2(float(i), float(j))));
            total += length(color.rgb - other.rgb);
        }
    }
    return total/8.0;
}

vec4 pixelate(vec2 pos, vec2 outPos) {
    vec4 col = texture2D(u_Tex0, proj0(pos));
    float resolution = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    vec4 sampledColor;
    vec2 uu;
    float scale = 1.0/ resolution;
    for(int i=0; i<5; ++i) {
        scale *= 2.0;
        uu = floor(pos/scale + 0.5);
        vec2 u = uu * scale;
        sampledColor = texture2D(u_Tex0, proj0(u));
        float scale2 = u_Regularity==0.0 ? 0.0000001 : u_Regularity*0.02*scale;
        float dist = getAvgDistance(sampledColor, floor(pos/scale2+0.5)*scale2, scale);
        if (dist >= (0.5 + u_Balance*0.005) * 1.717) break;
    }

    if (u_Dithering!=0.0) {
        vec2 offset = vec2(fmod(uu.x, float(u_DitherWidth)), fmod(uu.y, float(u_DitherHeight)));
        float k = u_Dither[int(offset.x)+int(offset.y)*u_DitherWidth] * u_Dithering*0.03 * 1.4 / pow(float(u_ColorCount), 0.5);
        sampledColor.xyz *= 1.0+k;
    }
    vec4 outCol = getFromPalette(sampledColor);
    //vec4 outCol = sampledColor;

    float intensity = getLocus(pos, col, outCol);
    return mix(col, outCol, intensity);
}

#include mainWithOutPos(pixelate)
