precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include tex(1)

uniform float u_Intensity;
uniform float u_Range;


vec4 darken(vec2 pos, vec2 outPos) {
    vec4 base = texture2D(u_Tex0, proj0(pos));
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);

    float slopeLen = 0.2;
    float slopeStart = -slopeLen + (1.0+2.0*slopeLen)*u_Range*0.01;
    float lum = (base.r+base.g+base.b)/3.0;
    float darken = 0.0;
    if (lum>=slopeStart+slopeLen) darken = 1.0;
    else if (lum>slopeStart) {
        darken = (lum-slopeStart)/slopeLen;
    }

    return darken*base * intensity;
}

#include mainWithOutPos(darken)
