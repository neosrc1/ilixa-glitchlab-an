precision highp float;
precision highp int;

#include commonvar
#include commonfun

uniform float u_Count;

vec4 color(vec2 pos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));
    float count = max(1.0, u_Count-1.0);
    return vec4(floor(color.rgb*count+0.5)/count, color.a);
}

#include mainPerPixel(color)
