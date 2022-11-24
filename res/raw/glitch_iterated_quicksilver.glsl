precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include tex(1)
#include hsl
#include locuswithcolor

uniform float u_Intensity;
uniform float u_Phase;
uniform int u_Count;
uniform vec4 u_Color;
uniform float u_Tolerance;

vec4 disp(vec2 pos, vec2 outPos) {
//    vec4 color = texture2D(u_Tex0, proj0(pos));
//    if (length(color.rgb-u_Color.rgb)>=u_Tolerance*0.017321) return color;
    vec2 origPos = pos;

    float intensity = getMaskedParameter(u_Intensity, outPos) * (u_LocusMode>=6 ? 1.0 : getLocus(pos, vec4(0.0, 0.0, 0.0, 0.0)));
    vec2 originalPos = pos;
    if (intensity != 0.0) {
        for(int i=0; i<u_Count; ++i) {
    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy;
            vec4 val = u_Tex1Transform[2][2]==0.0 ? texture2D(u_Tex0, proj0(t)) : texture2D(u_Tex1, proj1(t));
            val.xy -= vec2(0.5, 0.5);
            vec2 tt = u_Phase==0.0
                ? val.xy
                : vec2(cos(u_Phase)*val.x-sin(u_Phase)*val.y, cos(u_Phase)*val.y+sin(u_Phase)*val.x);
            vec2 displacement = intensity * 0.004 * tt;
            pos += displacement;
        }
    }
    float displacementLen = length(pos-originalPos);
    float maxDisplacement = float(u_Count)*intensity*0.004*0.707;
    float disp = displacementLen/maxDisplacement;
    vec4 outCol = texture2D(u_Tex0, proj0(pos));

//        float hueShift = disp<0.25  ? 0.0 : (disp-0.25)*360.0;
//        float saturation = disp<0.25  ? 0.0 : (disp-0.25)/0.75;
//        vec4 hsl = RGBtoHSL(outCol);
//        hsl[0] += hueShift;
//        hsl[1] = saturation;
//        outCol = HSLtoRGB(hsl);

    if (u_LocusMode>=6) {
        vec4 col = texture2D(u_Tex0, proj0(origPos));
        float locIntensity = getLocus(origPos, col, outCol);
        return mix(col, outCol, locIntensity);
    }
    else {
        return outCol;
    }
}

#include mainWithOutPos(disp)