precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform int u_Count;

vec2 f1(vec2 u, vec2 split) {
	int N = u_Count;
    for(int i=0; i<N; ++i) {
        vec2 scale;
        vec2 center;
        if (u.x>split.x && u.y>split.y) {
            scale = 2.0/vec2(1.0-split.x, 1.0-split.y);
            center = vec2(1.0+split.x, 1.0+split.y)/2.0;
        }
        else if (u.x<=split.x && u.y>split.y) {
            scale = 2.0/vec2(1.0+split.x, 1.0-split.y);
            center = vec2(-1.0+split.x, 1.0+split.y)/2.0;
        }
        else if (u.x>split.x) {
            scale = 2.0/vec2(1.0-split.x, 1.0+split.y);
            center = vec2(1.0+split.x, -1.0+split.y)/2.0;
        }
        else {
            scale = 2.0/vec2(1.0+split.x, 1.0+split.y);
            center = vec2(-1.0+split.x, -1.0+split.y)/2.0;
        }
        u = u*scale - center*scale;
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
