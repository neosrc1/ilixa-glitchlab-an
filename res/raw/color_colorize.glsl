precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include color

uniform float u_Intensity;
uniform float u_Saturation;
uniform vec4 u_Color;

vec4 color(vec2 pos) {
    vec4 inc = texture2D(u_Tex0, proj0(pos));

    vec4 rgb = colorize(inc, u_Color, u_Saturation*0.01);

    float intensity = getMaskedParameter(u_Intensity, pos);
    return mix(inc, rgb, intensity*0.01);
}

#include mainPerPixel(color)
