precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include tex(1)

uniform float u_Intensity;
uniform float u_Red;
uniform float u_Green;
uniform float u_Blue;

vec4 gdiff(vec2 pos) {
    vec4 c1 = texture2D(u_Tex0, proj0(pos));
    vec4 c2 = texture2D(u_Tex1, proj1(pos));
    vec3 diff = clamp(c1.rgb-c2.rgb, 0.0, 1.0);
    float grey = clamp((diff.r + diff.g + diff.b) / 3.0, 0.0, 1.0);

    return vec4(grey, grey, grey, c1.a);
}

#include mainPerPixel(gdiff) // should disable antialias
