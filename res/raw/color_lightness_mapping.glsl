precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform sampler2D u_Palette;

vec4 map(vec2 pos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));
    float total = (color.r + color.g + color.b) * 255.0/3.0;

    float x = (0.5 + total)/256.0;
    vec4 mapped = texture2D(u_Palette, vec2(x, 0.0));
//    vec4 mapped = texture2D(u_Palette, vec2(proj0(pos).x*3.0, 0.0));

    float intensity = getMaskedParameter(u_Intensity, pos);
    return mix(color, mapped, intensity*0.01);
}

#include mainPerPixel(map) // should disable antialias
