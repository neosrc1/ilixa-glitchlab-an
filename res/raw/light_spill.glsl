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
uniform vec4 u_Color1;

float hash1(vec2 p) {
    vec2 a = fract(-45.3277*p.xy);
    vec2 b = a + dot(a, a+123.3371);
	return fract(b.x*b.y);
}


vec2 rndUnit(vec2 p) {
    //return vec2(hash(p)-0.5, hash(p+10.8887)-0.5);
    return normalize(vec2(hash1(p)-0.5, hash1(p+10.8887)-0.5));
}

float dotGridGradient(vec2 g, vec2 u) {
    return dot(u-g, rndUnit(g));
}

float smix(float a, float b, float k) {
    return mix(a, b, smoothstep(0.0, 1.0, k));
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




vec3 spilloverRGB(vec3 c) {
    vec3 extra = c - 1.0;
    float bonus = (max(0.0, c.r) + max(0.0, c.g) + max(0.0, c.b))/3.0;
    return vec3(min(1.0, c.r+bonus), min(1.0, c.g+bonus), min(1.0, c.b+bonus));
}


vec3 gradient(float x) {
    vec3 c = vec3(0.0);
    float k = (x+1.0)*2.0;
    if (k<1.0) {
        c = vec3(1.0, k, 0.0);
    }
    else if (k<2.0) {
        c = vec3(2.0-k, 1.0, 0.0);
    }
    else if (k<3.0) {
        c = vec3(0.0, 1.0, k-2.0);
    }
    else {
        c = vec3(0.0, 4.0-k, 1.0);
    }

    c += smoothstep(2.0- 0.015*u_Dispersion, 0.2, abs(x));
    //c += 2.0*smoothstep(30.0, 15.0, u_Dispersion) * smoothstep(1.0, 0.8, abs(x));

    c = mix(c, vec3(2.0*smoothstep(1.5, 0.5, abs(x))), smoothstep(25.0, 0.0, u_Dispersion));

    //c += smoothstep(0.99, 0.2, abs(x));
    //c += smoothstep(1.5, 0.5, abs(x));
    //c += smoothstep(0.99, 0.8, abs(x));

    //return spilloverRGB(c) * smoothstep(1.25, 0.75, abs(x));
    return c * smoothstep(1.25, 0.75, abs(x));
}


vec3 desaturate(vec3 c, float k) {
    float grey = (c.r+c.g+c.b)/3.0;
    return mix(c, vec3(grey), k);
}

vec3 spill(vec2 u) {
    float S = 5.0;
    float seed = u_Seed;
    float variability = (100.0-u_Regularity)*0.01;
    u += variability*5.0*perlin(0.15*u+u_Seed);
    mat2 t = mat2(1.0+variability*0.5*sin(u.x+u_Seed*S*1.2), variability*0.75*sin(0.55+0.5*u_Seed*S*0.943),
    variability*0.75*sin(0.8989+u_Seed*S*0.777), 1.0+variability*0.5*sin(u.y*0.5+1.55+u_Seed*S*1.111) );
    u = t*u;
    u += variability*0.5*vec2(sin(1.2+u.y*0.5+u_Seed), sin(u.x*0.5+u_Seed*0.555));
    return desaturate(gradient(u.x) * smoothstep(8.0, 5.0, length(u)), smoothstep(0.25, 0.0, u_Dispersion*0.01));
}



vec4 spilllight(vec2 pos, vec2 outPos) {
    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec4 color = texture2D(u_Tex0, proj0(pos));

    float intensity = getMaskedParameter(u_Intensity, outPos);
    color.rgb += intensity*0.02 * spill(t)*u_Color1.rgb;

    return color;
}

#include mainWithOutPos(spilllight)
