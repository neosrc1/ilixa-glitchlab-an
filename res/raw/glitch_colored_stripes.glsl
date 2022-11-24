precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include smoothrandom
#include hsl
#include locuswithcolor

uniform vec4 u_Color;
uniform mat3 u_InverseModelTransform;
uniform float u_Variability;
uniform float u_ColorVariability;
uniform float u_Seed;

vec4 getColor(vec4 color, vec2 delta) {
    float deltaHue = delta.x * u_ColorVariability*0.02;
    vec4 hsl = RGBtoHSL(color);
    hsl.x += deltaHue*180.0;
    hsl.z *= (1.0 + 0.3*delta.y);
    return HSLtoRGB(hsl);
}

vec4 colorize(vec4 base, vec4 tint) {
    vec4 hslBase = RGBtoHSL(base);
    vec4 hslTint = RGBtoHSL(tint);
    float kCol = clamp(tint.a*2.0, 0.0, 1.0);
    hslTint.z = hslBase.z;
    vec4 tintLum = HSLtoRGB(hslTint);
    vec3 colorized = mix(base.rgb, tintLum.rgb, kCol);//HSLtoRGB(hslBase);
    float kMate = clamp((tint.a-0.5)*2.0, 0.0, 1.0);
    return vec4(mix(colorized, tint.rgb, kMate), base.a);
}

vec4 streak(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec4 inCol = texture2D(u_Tex0, proj0(pos));
    float index = floor(u.y/2.0);
    vec2 delta = rand2relSeeded(vec2(index, index), u_Seed);
    float var = u_Variability*0.01 * delta.x * 2.0;
    float inside = (fmod(u.y, 2.0) < 1.0+var) ? 1.0 : 0.0;

    if (inside>0.0) {
        vec4 color = getColor(u_Color, delta);
        vec4 outCol = colorize(texture2D(u_Tex0, proj0(pos)), color);
        float k = getLocus(pos, inCol, outCol);
        return mix(inCol, outCol, k);
    }
    else {
        return inCol;
    }
}

#include mainWithOutPos(streak)
