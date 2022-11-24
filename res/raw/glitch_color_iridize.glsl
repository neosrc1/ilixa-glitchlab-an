precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include locuswithcolor
#include tex(1)

uniform float u_Mode;
uniform float u_Mode2;
uniform float u_Intensity;
uniform float u_Balance;


float getChannel(int select, vec4 rgb, vec4 hsl) {
    if (select==0) return rgb.r;
    else if (select==1) return rgb.g;
    else if (select==2) return rgb.b;
    else if (select==3) return hsl.r;
    else if (select==4) return hsl.g;
    else if (select==5) return hsl.b;
    else if (select==6) return 1.0-rgb.r;
    else if (select==7) return 1.0-rgb.g;
    else if (select==8) return 1.0-rgb.b;
    else if (select==9) return 1.0-hsl.r;
    else if (select==10) return 1.0-hsl.g;
    else return 1.0-hsl.b;
}

vec4 swap(vec4 rgb, float mode) {
    float coding = floor(mode);
    bool toHsl = coding >= 1728.0;
    if (toHsl) coding = fmod(coding, 1728.0);
    vec4 hsl = RGBtoHSL(rgb);
    hsl.r /= 360.0;
    int rChannel = int(fmod(coding, 12.0));
    int gChannel = int(fmod(coding/12.0, 12.0));
    int bChannel = int(fmod(coding/144.0, 12.0));
    vec4 color = vec4(
        getChannel(rChannel, rgb, hsl) * (toHsl ? 360.0 : 1.0),
        getChannel(gChannel, rgb, hsl),
        getChannel(bChannel, rgb, hsl),
        rgb.a );

    return toHsl ? HSLtoRGB(color) : color;
}

vec4 offset(vec2 pos) {
    vec4 rgb = texture2D(u_Tex0, proj0(pos));
    vec4 mapRgb = u_Tex1Transform[2][2]==0.0 ? rgb : texture2D(u_Tex1, proj1(pos));
    if (u_Mode>=0.0) { rgb = swap(rgb, u_Mode); mapRgb = swap(mapRgb, u_Mode); }

    vec4 hsl = RGBtoHSL(rgb);
    vec4 mapHsl = RGBtoHSL(mapRgb);

    float saturation = mapHsl.g;
    float satBal = u_Balance*0.005+0.5;
    hsl.g = saturation * smoothstep(0.0, 1.0, (saturation-satBal)*4.0+0.5);


    float intensity = getMaskedParameter(u_Intensity, pos) * 0.4;
    hsl.r = mapHsl.r * (1.0 + saturation*intensity);

    vec4 outCol = HSLtoRGB(hsl);
    if (u_Mode2>=0.0) { outCol = swap(outCol, u_Mode2); }

    return mix(rgb, outCol, getLocus(pos, outCol));
}

#include mainPerPixel(offset)
