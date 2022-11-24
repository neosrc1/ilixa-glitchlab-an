precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform float u_Red_to_red;
uniform float u_Green_to_red;
uniform float u_Blue_to_red;
uniform float u_Red_to_green;
uniform float u_Green_to_green;
uniform float u_Blue_to_green;
uniform float u_Red_to_blue;
uniform float u_Green_to_blue;
uniform float u_Blue_to_blue;
uniform int u_Mode;

vec4 mix(vec2 pos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));
    float totalRed = 3.0;
    float totalGreen = 3.0;
    float totalBlue = 3.0;
    if (u_Mode==1) {
        totalRed = u_Red_to_red + u_Green_to_red + u_Blue_to_red;
        totalGreen = u_Red_to_green + u_Green_to_green + u_Blue_to_green;
        totalBlue = u_Red_to_blue + u_Green_to_blue + u_Blue_to_blue;
    }

    float red = totalRed==0.0
        ? 0.0
        : clamp(dot(color.rgb, vec3(u_Red_to_red, u_Green_to_red, u_Blue_to_red)) / totalRed, 0.0, 1.0);
    float green = totalGreen==0.0
        ? 0.0
        : clamp(dot(color.rgb, vec3(u_Red_to_green, u_Green_to_green, u_Blue_to_green)) / totalGreen, 0.0, 1.0);
    float blue = totalBlue==0.0
        ? 0.0
        : clamp(dot(color.rgb, vec3(u_Red_to_blue, u_Green_to_blue, u_Blue_to_blue)) / totalBlue, 0.0, 1.0);

    float intensity = 100.0; //getMaskedParameter(u_Intensity, pos);
    return mix(color, vec4(red, green, blue, color.a), intensity*0.01);
}

#include mainPerPixel(mix) // should disable antialias
