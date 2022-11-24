precision highp float;
precision highp int;

#include commonvar
#include commonfun

uniform sampler2D u_Palette;
uniform int u_ColorCount;

vec4 color(vec2 pos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));

    float closestDist = 10000000.0;
    vec4 closestColor;
    for(int i=0; i<u_ColorCount; ++i) {
        float x = (0.5 + float(i))/float(u_ColorCount);
        vec4 c = texture2D(u_Palette, vec2(x, 0.0));
        float dist = length(color-c);
        if (dist < closestDist) {
            closestColor = c;
            closestDist = dist;
        }
    }

    return closestColor;
}

#include mainPerPixel(color)
