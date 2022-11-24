precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Dampening;
uniform float u_Balance;
uniform float u_Brightness;

vec4 blurH(vec2 pos, float radius) {
    float pixel = 2.0 / u_Tex0Dim.y;
    int n = int(ceil(radius / pixel))+1;
    vec4 total = vec4(0.0, 0.0, 0.0, 0.0);
    vec2 p = pos - vec2(float(n)*pixel, 0.0);
    float div = 0.0;
    for(int i=-n; i<=n; ++i) {
        float d = length(vec2(float(i), 0.0)) * pixel / radius;
        if (d<=1.0) {
            float k = (d>0.5) ? (1.0-d)*(1.0-d)*2.0 : 1.0 - d*d*2.0;
            total += k*texture2D(u_Tex0, proj0(p));
            div += k;
            p.x += pixel;
        }
    }
    return total / div;
}

vec4 crtContrast(vec2 pos, float k, float radius) {
    vec4 color = texture2D(u_Tex0, proj0(pos));
    vec4 blur = blurH(pos+vec2(radius/2.0, 0.0), radius);
    return (1.0+k)*color - k*blur;
}

vec4 chromaOffset(vec4 col, vec2 pos) {
    vec2 u = vec2(pos.x + 0.05, pos.y); //(u_ModelTransform * vec3(pos, 1.0)).xy;
    vec4 hsl = RGBtoHSL(col);
    vec4 origHsl = hsl;
    vec4 offHsl = RGBtoHSL(texture2D(u_Tex0, proj0(u)));
    hsl[0] = offHsl[0];
    hsl[1] = offHsl[1];
    return HSLtoRGB(hsl);
}

vec2 pincushion(vec2 p, float k) {
	return p*(1.0+k*dot(p, p)*dot(p, p));
	//return p*(1.0+k*dot(p, p));
}

vec4 scanlines(vec4 col, vec2 pos) {
    vec4 hsl = RGBtoHSL(col);
    vec4 origHsl = hsl;

    vec2 pinc = pincushion(pos, 0.15);
//    vec2 pin = (u_ModelTransform * vec3(pinc, 1.0)).xy;
    hsl[0]+=pinc.y*1000.0;
    float brightness = -u_Brightness;//25.0;
    float b = pow(1.04, brightness);
    hsl[2] *= pow((1.0+sin(pinc.y*600.0))*(brightness*0.001+0.5), b);

    vec4 hslD = origHsl;
    hslD[2] = hsl[2];
    vec4 rgbD = HSLtoRGB(hslD);
    vec4 rgb = HSLtoRGB(hsl);
    rgb = mix(rgb, rgbD, 0.0);

    return mix(col, rgb, 0.4);
}

vec4 ray(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float k = fmod(u.y+2.0, 2.0)*0.5;

    vec4 color = crtContrast(pos, 0.8, 0.025); //texture2D(u_Tex0, proj0(pos));
    color = chromaOffset(color, pos);
    color = scanlines(color, pos);
//return color;
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);
//    float base = pow(10.0, intensity*20.0);
//    k = 0.5*pow(base, k)/(base/10.0) + 0.5*(pow(10000.0, k)/1000.0);
//    k = max(pow(base, k)/(base/10.0), (pow(1000.0, k)/100.0));

    float base = pow(10.0, intensity*20.0);
    k = u_Balance*0.01 + 0.5*pow(base, k)/(base/10.0);

    vec4 outCol = color*vec4(k, k, k, 1.0);
    return mix(color, outCol, clamp(0.0, 1.0, intensity*3.0));
}


#include mainWithOutPos(ray)
