precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include locuswithcolor

uniform float u_Mode;
uniform float u_Intensity;

//float getChannel(int select, vec4 rgb, vec4 hsl) {
//    if (select==0) return rgb.r;
//    else if (select==1) return rgb.g;
//    else if (select==2) return rgb.b;
//    else if (select==3) return hsl.r;
//    else if (select==4) return hsl.g;
//    else return hsl.b;
//}

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

//vec4 offset(vec2 pos) {
//    float mode = u_Mode;
//    float coding = floor(mode*0.01*2.0*6.0*6.0*6.0-1.0);
//    bool toHsl = coding > 215.0;
//    if (toHsl) coding = fmod(coding, 216.0);
//
//    vec4 rgb = texture2D(u_Tex0, proj0(pos));
//    vec4 hsl = RGBtoHSL(rgb);
//    hsl.r /= 360.0;
//    int rChannel = int(fmod(coding, 6.0));
//    int gChannel = int(fmod(coding/6.0, 6.0));
//    int bChannel = int(fmod(coding/36.0, 6.0));
//    vec4 color = vec4(
//        getChannel(rChannel, rgb, hsl) * (toHsl ? 360.0 : 1.0),
//        getChannel(gChannel, rgb, hsl),
//        getChannel(bChannel, rgb, hsl),
////        getChannel(0, rgb, hsl) * (toHsl ? 360.0 : 1.0),
////        getChannel(1, rgb, hsl),
////        getChannel(2, rgb, hsl),
//        rgb.a );
//
//    vec4 outCol = toHsl ? HSLtoRGB(color) : color;
//
//    float intensity = getMaskedParameter(u_Intensity, pos) * 0.01;
//    intensity *= getLocus(pos, outCol);
//    return mix(rgb, outCol, intensity);
//}

vec4 offset(vec2 pos) {
    float mode = u_Mode;
    float coding = floor(mode);
    bool toHsl = coding >= 1728.0;
    if (toHsl) coding = fmod(coding, 1728.0);

    vec4 rgb = texture2D(u_Tex0, proj0(pos));
    vec4 hsl = RGBtoHSL(rgb);
    hsl.r /= 360.0;
    int rChannel = int(fmod(coding, 12.0));
    int gChannel = int(fmod(coding/12.0, 12.0));
    int bChannel = int(fmod(coding/144.0, 12.0));
    vec4 color = vec4(
        getChannel(rChannel, rgb, hsl) * (toHsl ? 360.0 : 1.0),
        getChannel(gChannel, rgb, hsl),
        getChannel(bChannel, rgb, hsl),
//        getChannel(0, rgb, hsl) * (toHsl ? 360.0 : 1.0),
//        getChannel(1, rgb, hsl),
//        getChannel(2, rgb, hsl),
        rgb.a );

    vec4 outCol = toHsl ? HSLtoRGB(color) : color;

    float intensity = getMaskedParameter(u_Intensity, pos) * 0.01;
    intensity *= getLocus(pos, outCol);
    return mix(rgb, outCol, intensity);
}

#include mainPerPixel(offset)
