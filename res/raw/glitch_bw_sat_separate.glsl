precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl

uniform float u_Intensity;
uniform float u_Balance;

float threshold (float l, float y) {
    float t = (1.0+sin(y*1000.0))*0.5;
    return l < t ? 0.0 : 1.0;
}
float threshold2 (float l, vec2 uv) {
    float t = (1.0+(sin(uv.y*800.0)*sin(uv.x*800.0)))*0.5;
    return l < t ? 0.0 : 1.0;
}
vec2 pixelize(vec2 p) {
	return floor(p*40.0)/40.0;
}

vec4 removeGreen(vec4 hsl, vec4 origHsl) {
    float h = fmod(hsl[0], 360.0);
    hsl[0] = h;
    if (h>30.0 && h<200.0) {
    	hsl[1] = smoothstep(0.0, 1.0, abs(h-115.0)/85.0);
        //hsl[2] += smoothstep(0.3, 0.0, abs(h-120.0)/40.0);
        //hsl[2] += smoothstep(0.3, 0.0, abs(h-120.0)/40.0);
    }
    return mix(origHsl, hsl, hsl[1]);
}

vec4 offset(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec4 col = texture2D(u_Tex0, proj0(pos));
    vec4 hsl = RGBtoHSL(col);
    vec4 origHsl = hsl;

    hsl[1] = hsl[1]<(u_Balance*0.005+0.5) ? 0.0 : 1.0;
    if (hsl[1]==0.0) {
        //hsl[2] = threshold2(hsl[2], u);
        hsl[2] = threshold(hsl[2], u.y);
        //hsl = RGBtoHSL(texture2D(u_Tex0, proj0(pixelize(pos))));

    }
    else {
        hsl[0]+=u.x*5000.0;
        hsl = removeGreen(hsl, origHsl);
    }
    return HSLtoRGB(hsl);
}

#include mainWithOutPos(offset)
