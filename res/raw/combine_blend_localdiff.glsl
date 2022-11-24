precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include tex(1)

uniform float u_Radius;
uniform float u_Angle;
uniform float u_Kbase;
uniform float u_Kabs;
uniform float u_Krel;
uniform float u_Intensity;

vec4 toGrey(vec4 color) {
    float g = (color.r + color.g + color.b) / 3.0;
    return vec4(g, g, g, color.a);
}

vec4 blend(vec2 pos, vec2 outPos) {
    vec2 delta = u_Radius * vec2(cos(u_Angle), sin(u_Angle));

    vec4 inc1 = texture2D(u_Tex0, proj0(pos));
    vec4 inc2a = toGrey(texture2D(u_Tex1, proj1(pos+delta)));
    vec4 inc2b = toGrey(texture2D(u_Tex1, proj1(pos-delta)));
    vec3 diff = (inc2a - inc2b).rgb;

    float intensity = getMaskedParameter(u_Intensity*0.1, outPos);

    return vec4(
        u_Kbase*inc1.rgb + intensity * (u_Kabs*abs(diff) + u_Krel*diff),
//        inc1.rgb + intensity * diff,
        inc1.a );
}

#include mainWithOutPos(blend)
