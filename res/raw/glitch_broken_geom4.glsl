precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform int u_Count;

vec2 f1(vec2 u, vec2 split) {
	int N = u_Count;
    for(int i=0; i<N; ++i) {
        float type;
        if (u.x>split.x && u.y>split.y) {
            type = 0.0;
        }
        else if (u.x<=split.x && u.y>split.y) {
            type = 1.0;
        }
        else if (u.x>split.x) {
            type = 2.0;
        }
        else {
            type = 3.0;
        }
        type = fmod(type+float(i), 4.0);

        if (type==0.0) {
            u *= 2.0;
        }
        else if (type==1.0) {
            float ox = u.x;
        	u.x = -u.y;
            u.y = ox;
        }
        else if (type==2.0) {
            float ox = u.x;
        	u.x = u.y;
            u.y = -ox;
        }
        else {
            u /= 2.0;
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

    return texture2D(u_Tex0, proj0(f1(pos/vRatio, split)*vRatio));
}

#include mainWithOutPos(breakg)
