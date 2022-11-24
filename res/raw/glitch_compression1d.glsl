precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include locuswithcolor
#include tex(1)

uniform float u_Intensity;
uniform int u_Count;
uniform float u_Phase;
uniform float u_Phase2;

vec4 tex(vec2 p) {
    return (u_Tex1Transform[2][2]!=0.0) ? texture2D(u_Tex1, proj1(p)) : texture2D(u_Tex0, proj0(p));
}

vec4 compress(vec2 pos, vec2 outPos) {
    vec2 dir = vec2(sin(u_Phase), cos(u_Phase));
    vec2 dispDir = mat2(cos(u_Phase2), -sin(u_Phase2), sin(u_Phase2), cos(u_Phase2)) * vec2(sin(u_Phase), cos(u_Phase));
    vec2 pp = dot(dir, pos) * dir;
    vec2 p = (u_ModelTransform*vec3(pp, 1.0)).xy;
    float d = (length(tex(p).rgb)/1.73205-0.5)*2.0;

    vec4 color = texture2D(u_Tex0, proj0(pos));
    float intensity = getMaskedParameter(u_Intensity, outPos) * 0.04;
//    vec4 outColor = texture2D(u_Tex0, proj0(pp + dot(dispDir, pp-pos)*dispDir*(1.0+d)*intensity*d));
    vec4 outColor = texture2D(u_Tex0, proj0(pp + (pos-pp)*(1.0+d*intensity)));

    float k = getLocus(pos, outColor);
    return mix(color, outColor, k);
}

#include mainWithOutPos(compress)
