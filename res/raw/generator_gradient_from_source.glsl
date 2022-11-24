precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl

uniform float u_Intensity;
uniform float u_Distortion;
uniform float u_Saturation;
uniform float u_Tolerance;
uniform float u_Hue;
uniform float u_PosterizeCount;

vec4 gradient(vec2 pos, vec2 outPos) {
    vec2 u = pos;
    if (u_Distortion!=0.0) {
        vec2 v = (u_ModelTransform * vec3(pos, 1.0)).xy;
        u += u_Distortion*0.01 * vec2(sin(v.x*3.0), 0.0);
    }
    if (u_PosterizeCount<256.0) {
        u.x = floor(u.x*u_PosterizeCount+0.5) / u_PosterizeCount;
    }
    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    float x = u.x*ratio;//fmod(u.x, 1.0);// (0.5 + float(i))/float(u_ColorCount);
    vec4 color = texture2D(u_Tex0, proj0(vec2(x, 0.0)));
    if (u_Hue != 0.0) {
        vec4 hsl = RGBtoHSL(color);
        hsl[0] += u_Hue;
        color = HSLtoRGB(hsl);
    }
    return color;
}

#include mainWithOutPos(gradient)
