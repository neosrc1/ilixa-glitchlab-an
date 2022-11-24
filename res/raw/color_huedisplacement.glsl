precision highp float;
precision highp int;


#include math
#include commonvar
#include commonfun
#include hsl
#include color
#include tex(1)

uniform float u_Intensity;
uniform float u_Phase;
uniform float u_Saturation;
uniform float u_Distortion;

vec4 addHue(vec4 sourceColor, float hue, float saturation) {
    vec4 hslSource = RGBtoHSL(sourceColor);

    hslSource.r += hue;
    hslSource.g = 1.0*saturation + hslSource.g*(1.0-saturation);

    return HSLtoRGB(hslSource);
}

vec4 displace(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy;
    vec2 pos2 = pos;

    vec4 val = u_Tex1Transform[2][2]==0.0 ? texture2D(u_Tex0, proj0(t)) : texture2D(u_Tex1, proj1(t));
    val.xy -= vec2(0.5, 0.5);
    vec2 tt = u_Phase==0.0
        ? val.xy
        : vec2(cos(u_Phase)*val.x-sin(u_Phase)*val.y, cos(u_Phase)*val.y+sin(u_Phase)*val.x);
    vec2 displacement = u_Distortion * 0.04 * tt;
    pos2 += displacement;

    vec4 color = texture2D(u_Tex0, proj0(pos));
    vec4 color2 = texture2D(u_Tex0, proj0(pos2));

    float intensity = getMaskedParameter(u_Intensity, outPos);

    //return addHue(color, length(color2.rgb)*100.0*u_Intensity, u_Saturation*0.01);
    return addHue(color2, length(val.rgb)*intensity*3.0, u_Saturation*0.01);
}


void main()
{
    vec4 outc;

    if (u_Antialias==4) {
        vec2 outPos00 = (v_OutCoordinate * u_Tex0Dim + vec2(-0.333, -0.333)) / u_Tex0Dim;
        vec2 outPos10 = (v_OutCoordinate * u_Tex0Dim + vec2(0.333, -0.333)) / u_Tex0Dim;
        vec2 outPos01 = (v_OutCoordinate * u_Tex0Dim + vec2(-0.333, 0.333)) / u_Tex0Dim;
        vec2 outPos11 = (v_OutCoordinate * u_Tex0Dim + vec2(0.333, 0.333)) / u_Tex0Dim;

        vec2 pos00 = (u_ViewTransform * vec3(outPos00, 1.0)).xy;
        vec2 pos10 = (u_ViewTransform * vec3(outPos10, 1.0)).xy;
        vec2 pos01 = (u_ViewTransform * vec3(outPos01, 1.0)).xy;
        vec2 pos11 = (u_ViewTransform * vec3(outPos11, 1.0)).xy;
        outc = (displace(pos00, outPos00) +
            displace(pos10, outPos10) +
            displace(pos01, outPos01) +
            displace(pos11, outPos11) ) * 0.25;
    }
    else {
        vec2 pos = (u_ViewTransform * vec3(v_OutCoordinate, 1.0)).xy;
        outc = displace(pos, v_OutCoordinate);
    }

    gl_FragColor = blend(outc, v_OutCoordinate);

}

