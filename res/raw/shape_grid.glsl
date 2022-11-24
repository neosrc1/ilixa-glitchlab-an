precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math

uniform float u_Thickness;
uniform float u_Count;
uniform vec4 u_Color1;
uniform float u_Blur;

float distance(float x) {
    if (abs(x)>0.5) return abs(x)-0.5;

    float normalized = ((x+0.5)*u_Count + 0.5);
    return abs(fract(normalized)-0.5)/u_Count;
}

float response0(float d, float thickness) {
    float power = pow(0.9, (50.0-u_Blur));
    return pow(clamp(0.0, 1.0, d/thickness), power);
}

float response(float d, float thickness, float blur) {
    return  pow(smoothstep(thickness, thickness+blur, d), 0.3);
}

vec4 grid(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float thickness = pow(u_Thickness * 0.01, 2.0)* 0.25;
    float blur = u_Blur * 0.002;
    float d;
    if (abs(u.x)>0.5 || abs(u.y)>0.5) d = max(abs(u.x)-0.5, abs(u.y)-0.5);
    else d = min(distance(u.x), distance(u.y));

    float k = response(d, thickness, blur);
    vec4 bkgCol = texture2D(u_Tex0, proj0(pos));
    return mix(vec4(mix(bkgCol.rgb, u_Color1.rgb, u_Color1.a), bkgCol.a), bkgCol, k);
}

#include mainWithOutPos(grid)
