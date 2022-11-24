precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include perspective
#include random
#include hsl
#include locuswithcolor

uniform float u_Intensity;

vec4 strippes(vec2 pos, vec2 outPos) {
    float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[1][0]));
    vec2 tr = (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy;
    vec4 inCol = texture2D(u_Tex0, proj0(pos));
    vec4 hsl = RGBtoHSL(inCol);
    float lum = hsl[2];
    float d = 0.005 * getMaskedParameter(u_Intensity, outPos);
    float lum1 = lum+d;
    float lum2 = lum-d;
    float angle = floor(hsl[0]/60.0)*60.0 * M_PI/180.0;
    hsl[2] = fract(scale * (cos(angle)*(pos.x+tr.x) + sin(angle)*(pos.y+tr.y))) > 0.5  ? lum2 : lum1;
    vec4 outCol = HSLtoRGB(hsl);

    return mix(inCol, outCol, getLocus(pos, inCol, outCol));
}

#include mainWithOutPos(strippes)
