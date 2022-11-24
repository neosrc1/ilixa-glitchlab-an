precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include smoothrandom
#include hsl
#include locuswithcolor

uniform vec4 u_Color;
uniform mat3 u_InverseModelTransform;
uniform float u_Variability;
uniform float u_Intensity;
uniform float u_Seed;
uniform float u_Thickness;

vec4 colorize(vec4 base, vec4 tint) {
    vec4 hslBase = RGBtoHSL(base);
    vec4 hslTint = RGBtoHSL(tint);
    float kCol = clamp(tint.a*2.0, 0.0, 1.0);
    hslTint.z = hslBase.z;
    vec4 tintLum = HSLtoRGB(hslTint);
    vec3 colorized = mix(base.rgb, tintLum.rgb, kCol);//HSLtoRGB(hslBase);
    float kMate = clamp((tint.a-0.5)*2.0, 0.0, 1.0);
    return vec4(mix(colorized, tint.rgb, kMate), base.a);
}

vec4 streak(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

    vec4 inCol = texture2D(u_Tex0, proj0(pos));
    float index = floor(u.y/2.0);
    vec2 delta = rand2relSeeded(vec2(index, index), u_Seed);
    float var = u_Variability*0.01 * delta.x * 2.0;
    float inside = (fmod(u.y, 2.0) < 1.0+var) ? 1.0 : 0.0;
    vec2 loPos = floor(mat2(u_ModelTransform)/scale*pos*250.0)/250.0;
    if (inside>0.0) {
        float intensity = getMaskedParameter(u_Intensity*0.03, outPos);
        float noiseH = mix(250.0, 1.0, u_Thickness*0.01);
        float index = loPos.x + floor(loPos.y*noiseH)/noiseH*10000.0;
//        float index = loPos.x + loPos.y*100.0;
        float ind = index + u_Seed*10.0;
//        float base = fmod(sin(ind*0.1)+0.5*sin(ind*0.2)+0.75*sin(ind*0.5)+0.5*sin(ind*1.0)+0.5*sin(ind*2.5)+0.5*sin(ind*4.0), 1.0);
        float base = ((sin(ind*0.1)+0.5*sin(ind*0.2)+0.5*sin(ind*0.5)+0.5*sin(ind*1.0)+0.5*sin(ind*2.5)+0.5*sin(ind*4.0))/7.0+0.5) * mix(0.75, delta.y+0.5, u_Variability*0.01);
        vec2 rnd = rand2relSeeded(loPos, u_Seed);
        float g = 0.8 + 0.2*abs(rnd.x);
        float a = clamp(base + 0.5*abs(rnd.y), 0.0, 1.0);
        vec4 color = vec4(g, g, g, inCol.a);
        vec4 outCol = mix(inCol, color, clamp(a*intensity, 0.0, 1.0));
        float k = getLocus(pos, inCol, outCol);
        return mix(inCol, outCol, k);
    }
    else {
        return inCol;
    }
}

#include mainWithOutPos(streak)
