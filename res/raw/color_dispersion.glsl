precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Intensity;
uniform float u_Seed;
uniform float u_Regularity;
uniform float u_Dispersion;
uniform float u_Vignetting;
uniform int u_Count;
uniform vec4 u_Color1;

vec4 sample(vec2 center, vec2 pos, float k) {
    vec2 u = center + (pos-center) * (1.0+k);
    return texture2D(u_Tex0, proj0(u));
}


vec4 dust(vec2 pos, vec2 outPos) {

    //vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy;
    vec2 center = (u_ModelTransform * vec3(0.0, 0.0, 1.0)).xy;
    vec2 unitX = (u_ModelTransform * vec3(1.0, 0.0, 1.0)).xy;

    float intensity = getMaskedParameter(u_Intensity, outPos);

    float falloff = 1.0;
    if (u_Vignetting != 0.0) {
        float diag = max(1.0, u_Tex0Dim.x/u_Tex0Dim.y) * length(unitX-center);
        float len = length(outPos - center);
        float radius = (1.5-u_Vignetting*0.01) * diag;
        falloff = max(0.0, (1.0 - u_Vignetting*0.02*smoothstep(0.0, radius, len)));
    }

    float k = intensity*0.001 * falloff;

    if (k == 0.0) {
        return texture2D(u_Tex0, proj0(pos));
    }

    vec4 r = sample(center, pos, -k);
    vec4 y = sample(center, pos, -0.5*k);
    vec4 g = sample(center, pos, 0.0);
    vec4 c = sample(center, pos, 0.5*k);
    vec4 b = sample(center, pos, 1.5*k);
    vec4 color = vec4(r.r*0.66+0.33*y.r, 0.4*y.g+0.2*g.g+0.4*c.g, 0.15*c.b + 0.85*b.b, (r.a+y.a+g.a+c.a+b.a)*0.2);

    return color;
}

#include mainWithOutPos(dust)
