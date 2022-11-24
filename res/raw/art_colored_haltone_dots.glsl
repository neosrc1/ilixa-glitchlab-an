precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include locuswithcolor

uniform float u_Intensity;
uniform mat3 u_InverseModelTransform;


vec4 halftone(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    vec2 center = floor(u) + vec2(0.5, 0.5);
    vec2 centerAbs = (u_InverseModelTransform * vec3(center, 1.0)).xy;

    vec4 inCol = texture2D(u_Tex0, proj0(pos));
    float unitAbs = length(mat2(u_InverseModelTransform)*vec2(0.0, 1.0));
    vec2 delta = vec2(unitAbs, 0.0) * 0.5;
    vec4 sampleCol = (texture2D(u_Tex0, proj0(centerAbs))
        + texture2D(u_Tex0, proj0(centerAbs+delta))
        + texture2D(u_Tex0, proj0(centerAbs-delta))
        + texture2D(u_Tex0, proj0(centerAbs+delta.yx))
        + texture2D(u_Tex0, proj0(centerAbs-delta.yx))) / 5.0;

    float lum = (sampleCol.r+sampleCol.g+sampleCol.b)/3.0;
    float radius = lum*0.5;
    float k = 0.0;
    float d = length(u-center); //length(fract(u)-vec2(0.5, 0.5))/radius;
    if (d <= radius) {
        k = 1.0;
    }
    vec4 paintCol = sampleCol;
    vec4 hsl = RGBtoHSL(sampleCol);
    hsl[2] = max(hsl[2], 0.5);
    paintCol = HSLtoRGB(hsl);
    vec4 outCol = mix(vec4(0.0, 0.0, 0.0, 1.0), paintCol, k);

    float intensity = u_Intensity*0.01 * getLocus(pos, outCol);
    return mix(inCol, outCol, intensity);
}

#include mainWithOutPos(halftone)
