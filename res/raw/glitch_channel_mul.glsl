precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl

uniform float u_Hue;
uniform float u_Saturation;
uniform float u_Brightness;
uniform float u_Mode;
uniform float u_Red;
uniform float u_Blue;
uniform float u_Green;
uniform float u_Intensity;
uniform mat3 u_LocusTransform;
uniform int u_LocusMode;

float xor(float a, float b) {
	return abs(a-b);
}

float getBit(float index, float a, float b, float c, float d) {
    if (index<16.0) return fmod(floor(a/pow(2.0, index)), 2.0);
    if (index<32.0) return fmod(floor(b/pow(2.0, index-16.0)), 2.0);
    if (index<48.0) return fmod(floor(c/pow(2.0, index-24.0)), 2.0);
    else		    return fmod(floor(d/pow(2.0, index-48.0)), 2.0);
}

float getBlock0(vec2 pos) {
    float inside = 0.0;
    float i2 = floor(pos.x/10.0) + floor(pos.y/10.0);
    float divisor = floor(fmod((pos.x-2.0*pos.y)/200.0, 24.0))/2.0;
    for(int i=0; i<5; ++i) {
    	vec2 v = vec2(fmod(pos.x, 8.0), fmod(pos.y, 8.0));
        float index = v.x + v.y*8.0;
        //float ins = getBit(index, 85.0, 4344.0, 54500.0, 15222.0); //index<32.0 ? 1.0 : 0.0;
        float ins = getBit(index, fmod(i2*8877.0, 65536.0), fmod(55.0+i2*777.0, 65536.0),
                           fmod(i2*413.0, 65536.0), fmod(4445.0+i2*78.0, 65536.0));
        if (i==1 && ins==1.0) { inside = 0.0; break;}
        if (i==2 && ins==0.0) { inside = 1.0; break;}
        //if (i==3 && ins==0.0) { inside = 0.0; break;}
        inside = xor(inside, ins);
        pos = floor(pos/divisor);
    }
    return inside;
}

float getBlock(vec2 pos) {
    float inside = 0.0;
    float i2 = floor(pos.x/10.0) + floor(pos.y/10.0);
    float divisor = floor(fmod((pos.x-2.0*pos.y)/200.0, 24.0))/2.0;
    float threshold = fmod((pos.x+2.0*pos.y)/200.0, 24.0)/6.0;
    float total = 0.0;
    for(int i=0; i<5; ++i) {
    	vec2 v = vec2(fmod(pos.x, 8.0), fmod(pos.y, 8.0));
        float index = v.x + v.y*8.0;
        //float ins = getBit(index, 85.0, 4344.0, 54500.0, 15222.0); //index<32.0 ? 1.0 : 0.0;
        float ins = getBit(index, fmod(i2*8877.0, 65536.0), fmod(55.0+i2*777.0, 65536.0),
                           fmod(i2*413.0, 65536.0), fmod(4445.0+i2*78.0, 65536.0));
        total += ins;
        pos = floor(pos/divisor);
    }
    inside = total>=threshold ? 1.0 : 0.0;
    return inside;
}

float getLocus(vec2 pos, vec4 outCol) {
    vec2 u = (u_LocusTransform * vec3(pos, 1.0)).xy;
    if (u_LocusMode==1) {
        return max(abs(u.x), abs(u.y))>1.0 ? 0.0 : 1.0;
    }
    else if (u_LocusMode==2) {
        return smoothstep(0.5, 1.0, length(u));
    }
    else if (u_LocusMode==3) {
        return smoothstep(1.0, 0.5, length(u));
    }
    else if (u_LocusMode==4) {
        float hue = RGBtoHSL(texture2D(u_Tex0, proj0(pos))).x;
        float targetHue = fmod(u_LocusTransform[2][0] * 180.0, 360.0);
        float d = hue-targetHue;
        if (d < 0.0) d = -d;
        if (d > 180.0) d = 360.0-d;
        float maxD = 360.0/length(vec2(u_LocusTransform[0][0], u_LocusTransform[0][1]));
        d /= maxD;
        return smoothstep(1.0, 0.75, d);
    }
    else if (u_LocusMode==5) {
        vec2 v = floor(u*40.0);
        return getBlock(v);
    }
    else if (u_LocusMode==6) {
        vec4 inCol = texture2D(u_Tex0, proj0(pos));
        float colDist = length(inCol.rgb-outCol.rgb);
        float maxDist = 1.7 / length(vec2(u_LocusTransform[0][0], u_LocusTransform[0][1]));
        colDist /= maxDist;
        return smoothstep(1.0, 0.75, colDist);
    }
    return 1.0;
}

vec4 offset(vec2 pos) {
    float mode = floor(u_Mode);
    float rMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float gMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float bMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float hMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float sMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float lMul = fmod(mode, 4.0); mode = floor(mode/4.0);
    float range = 1.003921568627451;
    vec4 col = texture2D(u_Tex0, proj0(pos));
    vec4 rgb = col;
    rgb.r = fmod(rgb.r*rMul*u_Red*0.1, range);
    rgb.g = fmod(rgb.g*gMul*u_Green*0.1, range);
    rgb.b = fmod(rgb.b*bMul*u_Blue*0.1, range);
    vec4 hsl = RGBtoHSL(rgb);
    hsl.x = fmod(hsl.x*hMul*u_Hue*0.1, 360.0);
    hsl.y = fmod(hsl.y*hMul*u_Saturation*0.1, range);
    hsl.z = fmod(hsl.z*hMul*u_Brightness*0.1, range);
    vec4 outCol = HSLtoRGB(hsl);

    float intensity = getMaskedParameter(u_Intensity, pos) * 0.01;
    intensity *= getLocus(pos, outCol);
    return mix(col, outCol, intensity);
}

#include mainPerPixel(offset)
