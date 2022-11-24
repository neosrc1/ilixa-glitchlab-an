precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include locuswithcolor

uniform int u_Count;
uniform float u_Mode;

vec2 f1(vec2 u, vec2 split) {
	int N = u_Count;
	float ca = cos(0.3);
	float sa = sin(0.3);
	mat2 rot = mat2(ca, sa, sa, -ca);

    float mode = u_Mode;
	float mul = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
	float type1 = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
	float type2 = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
	float type3 = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);
	float type4 = floor(fmod(mode, 4.0)); mode = floor(mode/4.0);

    for(int i=0; i<N; ++i) {
        float type;
        if (u.x>split.x && u.y>split.y) {
            type = type1;
        }
        else if (u.x<=split.x && u.y>split.y) {
            type = type2;
        }
        else if (u.x>split.x) {
            type = type3;
        }
        else {
            type = type4;
        }
        type = floor(fmod(type+float(i)*mul, 4.0)); //u_Mode should affect the multiplier (among other things)


        if (type==0.0) {
            u *= 1.1;
        }
        else if (type==1.0) {
            u = rot*u/*(u-vec2(0.5, 0.5)) +*/+vec2(0.5, 0.5);
        }
        else if (type==2.0) {
            u = floor(u*10.0)/10.0;
        }
        else if (type==3.0) {
            u /= 1.1;
        }
    }
    return u;
}

vec4 breakg(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
//    vec2 u = (u_ModelTransform * vec3(0.0, 0.0, 1.0)).xy;
    vec2 split = fract(u)*2.0-1.0;
    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    vec2 vRatio = vec2(ratio, 1.0);

    vec4 outCol = texture2D(u_Tex0, proj0(f1(pos/vRatio, split)*vRatio));

    float k = getLocus(pos, outCol);
    if (k==1.0) return outCol;
    else return mix(texture2D(u_Tex0, proj0(pos)), outCol, k);
}

#include mainWithOutPos(breakg)
