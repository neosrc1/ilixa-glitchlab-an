precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform int u_Count;
uniform float u_Intensity;

vec2 f1(vec2 u, vec2 split, vec2 s, float intensity) {
	int N = u_Count;
	vec2 rnd = rand2rel(s);
    for(int i=0; i<N; ++i) {

        if (u.x>split.x && u.y>split.y) {
            u *= 1.0+rnd.x;
            //u.x += 0.02*u.y;
        }
        else if (u.x<=split.x && u.y>split.y) {
            float ox = u.x;
        	u.x = sign(rnd.x)*u.y;
            u.y = sign(rnd.y)*ox;
        }
        else if (u.x>split.x) {
            u.x += rnd.y*2.0;
        }
        else {
            u.x = fmod(sign(u.x)*pow(abs(u.x), rnd.y), 1.0);
            u.y = fmod(sign(u.y)*pow(abs(u.y), rnd.x), 1.0);
        }

        if (max(abs(u.x), abs(u.y))>1.5) {
            u *= pow(2.0, intensity);
        }

    }
    return u;
}

vec4 breakg(vec2 pos, vec2 outPos) {
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
//    vec2 u = (u_ModelTransform * vec3(0.0, 0.0, 1.0)).xy;

//    vec2 split = fract(u)*2.0-1.0;
    vec2 split = fract(u)*4.0-2.0;

    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    vec2 vRatio = vec2(ratio, 1.0);

    return texture2D(u_Tex0, proj0(f1(pos/vRatio, split, floor(u), intensity)*vRatio));
}

#include mainWithOutPos(breakg)
