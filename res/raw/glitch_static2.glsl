precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include locuswithcolor

uniform float u_ColorScheme;
uniform mat3 u_InverseModelTransform;
uniform float u_Intensity;
uniform float u_Seed;
uniform float u_Mode;
uniform float u_Balance;
uniform float u_Coverage;
uniform float u_Brightness;
uniform float u_Contrast;
uniform float u_Variability;
uniform float u_SubAspectRatio;


#define S smoothstep

float hash0(vec2 p) {
//    vec2 a = fract((u_Seed-145.3277)*p.xy);
//    vec2 b = a + dot(a, a+123.3371);
//	return fract(b.x*b.y);
    vec2 a = fract(-145.3277*p.xy);
    vec2 b = a + dot(a, a+vec2(-4.434, 43.3371));
	return fract(b.x*b.y);
}
float hash1(vec2 p) {
//    vec2 a = fract((u_Seed-145.3277)*p.xy);
//    vec2 b = a + dot(a, a+123.3371);
//	return fract(b.x*b.y);
    vec2 a = fract((u_Seed-145.3277)*p.xy);
    vec2 b = a + dot(a, a+vec2(-4.434, 43.3371));
	return fract(b.x*b.y);
}

float hashRep(vec2 p) {
    vec2 a = fract(vec2(15.3*(p.x+u_Seed), 60.15*(p.y-u_Seed+333.3)+10.1));
    vec2 b = a + 1.0*dot(a.yx, a+100.0+u_Seed);
	return fract(b.x*b.y);
}

float hashMoireCurve(vec2 p) {
    vec2 a = (10.11+20.0*sin(u_Seed*vec2(0.1, 0.166)))*(p+5000.0+u_Seed);
    vec2 b = a*0.001 + dot(a*0.001, a*0.001);
	return clamp(0.5+sin(p.x*b.x*0.001)*sin(p.y*b.y*0.001), 0.0, 1.0);
}

float hashBanding(vec2 p) {
    p += 5000.0;
    float k = 10.11+u_Seed;
    vec2 a = fract(k*p)*k;
    a = fract(k*a)*k;
    vec2 b = a + 0.0*dot(a, a);
	return abs(sin(p.x*b.x*0.001)*sin(p.y*b.y*0.001));
}

float hash(vec2 p) {
    return hash1(p);
}

vec2 rndUnit(vec2 p) {
    //return vec2(hash(p)-0.5, hash(p+10.8887)-0.5);
    return normalize(vec2(hash0(p)-0.5, hash0(p+10.8887)-0.5));
}

float noise0(vec2 p) {
    vec2 s = vec2(1.0, 0.0);
    vec2 f = floor(p);
    vec2 d = p-f;
    float h00 = hash(f);
    float h10 = hash(f+s);
    float h01 = hash(f+s.yx);
    float h11 = hash(f+s.xx);

	return mix(mix(h00, h10, d.x), mix(h01, h11, d.x), d.y);
}

float noise1(vec2 p) {
    vec2 s = vec2(1.0, 0.0);
    vec2 f = floor(p);
    vec2 d = p-f;
    float h00 = hash1(f);
    float h10 = hash1(f+s);
    float h01 = hash1(f+s.yx);
    float h11 = hash1(f+s.xx);

	return mix(mix(h00, h10, S(0.0, 1.0, d.x)), mix(h01, h11, S(0.0, 1.0, d.x)), S(0.0, 1.0, d.y));
}

float noiseRep(vec2 p) {
    vec2 s = vec2(1.0, 0.0);
    vec2 f = floor(p);
    vec2 d = p-f;
    float h00 = hashRep(f);
    float h10 = hashRep(f+s);
    float h01 = hashRep(f+s.yx);
    float h11 = hashRep(f+s.xx);

	return mix(mix(h00, h10, S(0.0, 1.0, d.x)), mix(h01, h11, S(0.0, 1.0, d.x)), S(0.0, 1.0, d.y));
}

float noiseMoireCurve(vec2 p) {
    vec2 s = vec2(1.0, 0.0);
    vec2 f = floor(p);
    vec2 d = p-f;
    float h00 = hashMoireCurve(f);
    float h10 = hashMoireCurve(f+s);
    float h01 = hashMoireCurve(f+s.yx);
    float h11 = hashMoireCurve(f+s.xx);

	return mix(mix(h00, h10, S(0.0, 1.0, d.x)), mix(h01, h11, S(0.0, 1.0, d.x)), S(0.0, 1.0, d.y));
}

float noiseBanding(vec2 p) {
    vec2 s = vec2(1.0, 0.0);
    vec2 f = floor(p);
    vec2 d = p-f;
    float h00 = hashBanding(f);
    float h10 = hashBanding(f+s);
    float h01 = hashBanding(f+s.yx);
    float h11 = hashBanding(f+s.xx);

	return mix(mix(h00, h10, S(0.0, 1.0, d.x)), mix(h01, h11, S(0.0, 1.0, d.x)), S(0.0, 1.0, d.y));
}

float dotGridGradient(vec2 g, vec2 u) {
    return dot(u-g, rndUnit(g));
}

float smix(float a, float b, float k) {
    return mix(a, b, S(0.0, 1.0, k));
}

float perlin(vec2 p) {
    vec2 s = vec2(1.0, 0.0);
    vec2 f = floor(p);
    vec2 d = p-f;
    //return dotGridGradient(f, p);
    float ix0 = smix(dotGridGradient(f, p), dotGridGradient(f+s, p), d.x);
    float ix1 = smix(dotGridGradient(f+s.yx, p), dotGridGradient(f+s.xx, p), d.x);
    return 0.5+smix(ix0, ix1, d.y)*0.5;
}

float sinNoise(vec2 p) {
    float noiseH = 200.0;
    float index = p.x + floor(p.y*noiseH)/noiseH*10000.0;
    float ind = index+1000.0;// + u_Seed*10.0;
    float base = ((sin(ind*0.1)+0.5*sin(ind*0.2)+0.5*sin(ind*0.5)+0.5*sin(ind*1.0)+0.5*sin(ind*2.5)+0.5*sin(ind*4.0))/7.0+0.5);
    //return 0.3 + 0.5*abs(hash(p));
    return clamp(base + 0.0*abs(hash(p)), 0.0, 1.0);
}

float sinNoise2(vec2 p) {
    float noiseH = 5.0;
    float j0 = floor(p.y);
    float i0 = floor(p.x/noiseH);// + floor(p.y*noiseH);
    float i1 = i0+1.0;
    float dx = fract(p.x/noiseH);
    float h0 = hash(vec2(i0, j0))*6.28;
    float h1 = hash(vec2(i1, j0))*6.28;
    return sin(mix(h0, h1, dx))*0.5 + 0.5;
}

float perlin4(vec2 p) {
    return (perlin(p)+0.5*perlin(p*2.0)+0.25*perlin(p*4.0)+0.125*perlin(p*8.0))*0.6;
}

float contrast(float x, float c) {
    return 0.5 + (x-0.5)*(1.0+c);
}

float ccontrast(float x, float c) {
    return clamp(0.5 + (x-0.5)*(1.0+c), 0.0, 1.0);
}

vec3 colorScheme(vec3 rgb, float k) {
    float grey = (rgb.r+rgb.g+rgb.b)/3.0;
    if (k<0.2) return mix(vec3(rgb.g), vec3(grey), k*5.0);
    if (k<0.4) return mix(vec3(grey), rgb, (k-0.2)*5.0);
    return rgb;
}

vec2 aRatio(float a) {
	return vec2(a, 1.0)/(1.0+a)*2.0;
}

float staticNoise(vec2 u, float k) {
    float baseScale = 500.0;
    vec2 ar = aRatio(u_SubAspectRatio);
    if (k<0.25)  return mix(noise1(u*baseScale*ar), noiseMoireCurve(u*baseScale*ar), k*4.0);
    if (k<0.5)   return mix(noiseMoireCurve(u*baseScale*ar), noiseRep(u*baseScale*ar), (k-0.25)*4.0);
    if (k<0.75)  return mix(noiseRep(u*baseScale*ar), noiseBanding(u*baseScale*ar), (k-0.5)*4.0);
    else		 return mix(noiseBanding(u*baseScale*ar), noise1(u*baseScale*ar), (k-0.75)*4.0);
}

float bc(float x) {
    float y = x * (u_Brightness*0.01+1.0);
    y = (y-0.5)*u_Contrast + 0.5;
    return clamp(y, 0.0, 1.0);
}

vec4 staticN(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

    vec4 inCol = texture2D(u_Tex0, proj0(pos));
    float alpha = clamp(u_Coverage + ccontrast(perlin4(u*0.1*vec2(u_Variability*0.1, 100.0)), -5.0), 0.0, 1.0);
    alpha = smoothstep(0.15, 1.0, pow(alpha, 2.0)) * getMaskedParameter(u_Intensity, outPos)*0.01;

    float delta = (u_ColorScheme<40.0 ? 1.0 : u_ColorScheme-39.0)*0.1;
    vec3 rnd = vec3(staticNoise(pos, u_Mode*0.01), staticNoise(pos+delta, u_Mode*0.01), staticNoise(pos-delta, u_Mode*0.01));
    vec3 rgb = vec3(bc(rnd.r), bc(rnd.g), bc(rnd.b));

    vec2 d = (rnd.xy-0.5)*0.5;
    float balance = (u_Balance+100.0)/200.0;
    vec4 baseCol = texture2D(u_Tex0, proj0(pos + alpha*d*min(1.0, 2.0*(1.0-balance))));
    vec4 outCol = mix(baseCol, vec4(colorScheme(rgb, u_ColorScheme*0.01), 1.0), alpha * min(1.0, 2.0*balance));

    return mix(inCol, outCol, getLocus(pos, inCol, outCol));
}

#include mainWithOutPos(staticN)
