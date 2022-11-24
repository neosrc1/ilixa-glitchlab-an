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

    vec4 inCol = texture2D(u_Tex0, proj0(pos));
    if (abs(u.y)<1.0) {
        u.x += u_ModelTransform[2][0];
        vec2 p = (u_InverseModelTransform * vec3(u, 1.0)).xy;
        vec4 outCol = colorize(texture2D(u_Tex0, proj0(p)), u_Color);
        float k = getLocus(pos, inCol, outCol);
        return mix(inCol, outCol, k);
    }
    else {
        return inCol;
    }
}

#include mainWithOutPos(streak)
