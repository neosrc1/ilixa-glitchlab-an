precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include locuswithcolor

uniform float u_Intensity;
uniform float u_Balance;
uniform float u_RandomSeed;

vec2 distort(vec2 p, float k) {
    vec3 pp = vec3(p, u_RandomSeed);
    vec3 m = vec3(sin(u_RandomSeed), sin(u_RandomSeed+10.0), sin(-u_RandomSeed+20.0));
	pp.xyz += k * 1.000*sin( (2.0+m.x)*pp.yzx );
	pp.xyz += k * 0.75*sin( (2.0+m.y)*pp.yzx );
	pp.xyz += k * 0.5*sin( (2.0+m.z)*pp.yzx );
    return pp.xy;
}

vec4 offset(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec4 col = texture2D(u_Tex0, proj0(pos));
    vec4 hsl = RGBtoHSL(col);
//    hsl[0] = mix(fmod(distort(u, 1.1).x*2000.0, 360.0), hsl[0], hsl[1]);
    hsl[0] += distort(u, 1.1).x*2000.0*hsl[1];
    hsl[1] = mix(hsl[1], 1.0-hsl[1], u_Balance*0.005+0.5);
    vec4 outCol = HSLtoRGB(hsl);

    float k = getMaskedParameter(u_Intensity, outPos)*0.01 * getLocus(pos, outCol);
    return clamp(mix(col, outCol, k*2.0), 0.0, 1.0);
}

#include mainWithOutPos(offset)
