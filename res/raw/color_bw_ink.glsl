precision highp float;
precision highp int;

#include commonvar
#include commonfun

uniform float u_Balance;
uniform float u_Hardness;

float convert(float g) {
    float center = u_Balance*0.005 + 0.5;
    float radius = 0.1 - u_Hardness*u_Hardness*0.00001;
    float a = center - radius;
    float b = center + radius;
    return smoothstep(a, b, g);

    return floor(g+0.5);
}

vec4 color(vec2 pos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));
    float grey = convert((color.r + color.g + color.b) / 3.0);

    return vec4(grey, grey, grey, color.a);
}

#include mainPerPixel(color)
