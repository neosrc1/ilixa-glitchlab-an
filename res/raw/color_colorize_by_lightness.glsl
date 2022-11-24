precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include color

uniform vec4 u_Shadow;
uniform vec4 u_Midtone;
uniform vec4 u_Highligh;
uniform float u_Intensity;
uniform float u_Saturation;

vec4 triColorize(vec2 pos) {
    vec4 sourceColor = texture2D(u_Tex0, proj0(pos));

    vec4 outColor;
    float saturation = u_Saturation*0.01;
    float lightness = sourceColor.r + sourceColor.g + sourceColor.b;
    if (lightness<0.75) {
        outColor = colorize(sourceColor, u_Shadow, saturation);
    }
    else if (lightness<1.25) {
        float (k = lightness-0.75) * 2.0;
        outColor = colorize(sourceColor, mix(u_Shadow, u_Midtone, k), saturation);
    }
    else if (lightness<1.75) {
        outColor = colorize(sourceColor, u_Midtone, saturation);
    }
    float intensity = getMaskedParameter(u_Intensity, pos);
    return mix(sourceColor, outColor, intensity*0.01);
}

#include mainPerPixel(triColorize)
