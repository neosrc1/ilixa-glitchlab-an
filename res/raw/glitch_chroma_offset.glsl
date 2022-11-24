precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include locuswithcolor

uniform float u_Intensity;

vec4 offset(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec4 col = texture2D(u_Tex0, proj0(pos));
    vec4 hsl = RGBtoHSL(col);
    vec4 origHsl = hsl;
    vec4 offHsl = RGBtoHSL(texture2D(u_Tex0, proj0(u)));
    hsl[0] = offHsl[0];
    hsl[1] = offHsl[1];
    vec4 outCol = HSLtoRGB(hsl);
    float intensity = getMaskedParameter(u_Intensity, outPos) * 0.01 * getLocus(pos, outCol);
    return mix(col, outCol, intensity);
}

#include mainWithOutPos(offset)
