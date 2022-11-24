precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Distortion;
uniform float u_Ratio;
uniform mat3 u_InverseModelTransform;
uniform float u_Phase;
uniform int u_Mirror;

vec2 complex_mul(vec2 a, vec2 b) {
    return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x);
}

vec2 complex_inverse(vec2 a) {
    float r = a.x*a.x + a.y*a.y;
    return vec2(a.x/r, -a.y/r);
}

vec2 complex_div(vec2 a, vec2 b) {
    return complex_mul(a, complex_inverse(b));
}

float atan2(float y, float x) {
    if (abs(x) > abs(y)) return atan(y,x);
    else return M_PI/2.0 - atan(x,y);
}

vec2 complex_to_polar(vec2 a) {
    float r = sqrt(a.x*a.x + a.y*a.y);
    float arg = getVecAngle(a);//atan2(a.y, a.x); //acos(a.x/r);
    return vec2(r, arg);
}

vec2 complex_from_polar(float r, float arg) {
    return vec2(r*cos(arg), r*sin(arg));
}


vec2 complex_log(vec2 a) {
    vec2 polar = complex_to_polar(a);
    float r = log(polar.x);
    return vec2(r, polar.y);
}

vec2 complex_exp(vec2 a) {
    float r = exp(a.x);
    return vec2(r*cos(a.y), r*sin(a.y));
}

vec2 complex_pow(vec2 w, vec2 z) {
    vec2 wp = complex_to_polar(w);
    float r = wp.x;
    float theta = wp.y;
    float c = z.x;
    float d = z.y;
    float R = pow(r, c) * exp(-d*theta);
    float A = d*log(r)+c*theta;
    return R * vec2(cos(A), sin(A));
}


vec4 spiral(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);

    float intensity = getMaskedParameter(u_Intensity, outPos);
    float p = intensity > 0.0 ? 1.0/(1.0+intensity*0.1) : 1.0+pow(-intensity, 0.75);

    float angle = getVecAngle(u, d);

    float phase = u_Phase;
    float widthAngle = M_PI/4.0;

    if (u_Mirror==1) {
        angle = 2.0*(angle + phase);
        angle = fmod(angle, M_4PI);
        if (angle > M_2PI) { angle = M_4PI-angle; }
    }
    else {
        angle = angle + phase;
        angle = fmod(angle, M_2PI);
    }

    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    float scale360 = 1000.0/(u_Intensity*u_Intensity);
    float a = angle/M_2PI;
    float s = pow(scale360, a);
    vec2 w = vec2(
        (ratio<1.0?1.0:ratio)*angle/M_PI,
        (ratio<1.0?1.0/ratio:1.0) * log(d*s) / log(scale360));
//         log(d*(1.0 + angle/M_2PI*(scale360-1.0))) / log(scale360));

//    float sy = 4.0*log(d*(1.0 + angle/M_2PI*(scale360-1.0))) / log(scale360) - 1.0;
//    float sx = 4.0*ratio*angle/M_PI - 1.0;
//
//    vec2 coord = vec2(sx, sy);

//    vec2 coord = 4.0*u_Count *w;// - vec2(ratio, 1.0);
    vec2 coord = vec2(
        4.0*u_Count*w.x,
        2.0*fmod(w.y*u_Count, (ratio<1.0?1.0/ratio:1.0) *u_Count)-(ratio<1.0?1.0/ratio:1.0) *1.0);
    return texture2D(u_Tex0, proj0(coord));
}

vec4 spiral1(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);

    float intensity = getMaskedParameter(u_Intensity, outPos);
    float p = intensity > 0.0 ? 1.0/(1.0+intensity*0.1) : 1.0+pow(-intensity, 0.75);

    float angle = getVecAngle(u, d);

    float phase = u_Phase;
    float widthAngle = M_PI/4.0;

    if (u_Mirror==1) {
        angle = 2.0*(angle + phase);
        angle = fmod(angle, M_4PI);
        if (angle > M_2PI) { angle = M_4PI-angle; }
    }
    else {
        angle = angle + phase;
        angle = fmod(angle, M_2PI);
    }

    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    float scale360 = 1000.0/(u_Intensity*u_Intensity);
    float a = angle/M_2PI;
    float s = pow(scale360, a);
    float dd = log(d*s) / log(scale360);
    float ddd = fmod(dd, 1.0);
    vec2 coord = mix(ddd, exp(ddd)/exp(1.0), 1.0-u_Distortion*0.01) * vec2(cos(angle), sin(angle));
    return texture2D(u_Tex0, proj0(coord));
}

vec4 getAreaColor(vec2 u) {
    vec4 base = vec4(1.0, 0.0, 0.0, 1.0);
    if (u.x<0.0) {
        if (u.y<0.0) base.g = 1.0;
        else base = vec4(0.0, 0.0, 1.0, 1.0);
    }
    else if (u.y<0.0) {
        base.b = 1.0;
    }
    if (length(u)>1.0) base = vec4(0.0, 0.0, 0.0, 1.0);
    return base;
}


vec4 spiral2(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);

    float intensity = getMaskedParameter(u_Intensity, outPos);
    float p = intensity > 0.0 ? 1.0/(1.0+intensity*0.1) : 1.0+pow(-intensity, 0.75);

    float r1 = 1.0-intensity*0.01;
    float r2 = 1.0;

    float alpha = atan(log(r2/r1)/M_2PI);
    float f = cos(alpha);
    vec2 beta = f * vec2(cos(alpha), sin(alpha));//pow(exp(1.0), vec2(0, alpha));

    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;

//    vec2 w = r1 * complex_pow(u, -beta);
//    vec2 w = complex_pow(u/r1, beta);

//    vec2 ww = u;
    vec2 www = complex_log(u);
    vec2 ww = complex_mul(www, complex_from_polar(1.0/cos(alpha), -alpha));
    ww.x = fmod(ww.x, log(r2/r1));
    vec2 w = r1 * complex_exp(ww);
    vec4 base = getAreaColor(u);

    vec2 coord = w;
    return texture2D(u_Tex0, proj0(coord));
//    return mix(base, texture2D(u_Tex0, proj0(coord)), 0.5);
}


#include mainWithOutPos(spiral)
