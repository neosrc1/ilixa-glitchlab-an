precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform vec4 u_Color;

vec4 bw(vec2 pos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));

    float total = (u_Color.r + u_Color.g + u_Color.b);
    float grey = dot(u_Color.rgb, color.rgb) / total;

    float intensity = getMaskedParameter(u_Intensity, pos);
    return mix(color, vec4(grey, grey, grey, color.a), intensity*0.01);
}

#include mainPerPixel(bw) // should disable antialias
