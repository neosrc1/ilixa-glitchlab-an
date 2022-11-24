precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl

uniform float u_Intensity;
uniform float u_Dampening;
uniform float u_Brightness;
uniform float u_Distortion;
uniform float u_Count;

vec2 pincushion(vec2 p, float k) {
	return p*(1.0+k*dot(p, p)*dot(p, p));
	//return p*(1.0+k*dot(p, p));
}

vec4 offset(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec4 col = texture2D(u_Tex0, proj0(pos));
    vec4 hsl = RGBtoHSL(col);
    vec4 origHsl = hsl;
    //hsl[0] = mix(distort(uv, 0.1).x*2000.0, hsl[0], hsl[1]);
    //hsl[1] = 1.0-hsl[1];
    //hsl[0] += 5000.0*hsl[2]*hsl[1];

    float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    mat2 rot = mat2(u_ModelTransform)/scale;
    vec2 pinc = pincushion(pos, u_Distortion*0.0015);
    vec2 pin = (u_ModelTransform * vec3(pinc, 1.0)).xy;
    hsl[0]+=pin.y*2000.0;
    //hsl[1] *= 2.0;
    float b = pow(1.04, -u_Brightness);
    hsl[2] *= pow((1.0+sin((rot*pinc).y*u_Count))*(u_Brightness*0.001+0.5), b);
//    hsl[2] *= (1.0+sin(pincushion(u, u_Distortion*0.05).y*200.0))*(u_Brightness*0.005+0.5);

    vec4 hslD = origHsl;
    hslD[2] = hsl[2];
    vec4 rgbD = HSLtoRGB(hslD);
    vec4 rgb = HSLtoRGB(hsl);
    rgb = mix(rgb, rgbD, u_Dampening*0.01);

    float intensity = getMaskedParameter(u_Intensity, outPos) * 0.01;
    return mix(col, rgb, intensity);
}

#include mainWithOutPos(offset)
