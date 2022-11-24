precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform float u_Red;
uniform float u_Green;
uniform float u_Blue;
uniform int u_Mode;

vec4 bw(vec2 pos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));
    float total = 3.0;
    if (u_Mode==1) {
        total = u_Red + u_Green + u_Blue;
    }

    float grey = total==0.0
        ? 0.0
        : clamp(dot(color.rgb, vec3(u_Red, u_Green, u_Blue)) / total, 0.0, 1.0);

    float intensity = getMaskedParameter(u_Intensity, pos);
    return mix(color, vec4(grey, grey, grey, color.a), intensity*0.01);
}

#include mainPerPixel(bw) // should disable antialias
