precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

//uniform mat3 u_InverseModelTransform;

vec2 f1(vec2 u, vec2 split) {
	int N = 20;
    for(int i=0; i<N; ++i) {
        if (u.x>split.x && u.y>split.y) {
            u *= 2.0;
            //u.x += 0.02*u.y;
        }
        else if (u.x<=split.x && u.y>split.y) {
            float ox = u.x;
        	u.x = -u.y;
            u.y = ox;
        }
        else if (u.x>split.x) {
            u.x =u.x*2.0 - 1.0;
        }
        else {
            u.x = pow(u.x, 0.9);//u.x*u.x;//u.x*2.0;
            u.y = u.y*u.y;
        }
        //if (length(u)>1.5) {
        if (abs(u.x)+abs(u.y)>1.5) {
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
