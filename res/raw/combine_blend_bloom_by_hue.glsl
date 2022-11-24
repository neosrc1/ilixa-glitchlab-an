precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include tex(1)

uniform float u_Intensity;
uniform float u_Range;
uniform float u_Gamma;
uniform float u_Normalize;


vec4 blend(vec2 pos, vec2 outPos) {
    vec4 base = texture2D(u_Tex0, proj0(pos));
    vec4 bloom = texture2D(u_Tex1, proj1(pos));
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);
    float maxLum = 1.0 + intensity;

    float blooming = 0.0;
    float slopeLen = 0.2;
    float slopeStart = -slopeLen + (1.0+2.0*slopeLen)*u_Range*0.01;
    float lum = (bloom.r+bloom.g+bloom.b)/3.0;
    if (lum>=slopeStart+slopeLen) blooming = 1.0;
    else if (lum>slopeStart) {
        blooming = (lum-slopeStart)/slopeLen;
    }

    vec4 combined = base + blooming*bloom * intensity*3.0;
    vec4 normalized = vec4(combined.rgb / (1.0 + (maxLum-1.0)* u_Normalize*0.01), combined.a);

    if (u_Gamma!=0.0) {
        lum = (normalized.r+normalized.g+normalized.b)/3.0;
        float gammaCorrectedLum = pow(lum, pow(1.02, -u_Gamma));
        normalized.rgb = normalized.rgb * gammaCorrectedLum/lum;
    }

    return normalized;
}

#include mainWithOutPos(blend)
