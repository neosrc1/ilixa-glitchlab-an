precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include hsl

uniform int u_Count;
uniform float u_Intensity;

vec2 f1(vec2 u, vec2 split, vec4 style) {
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

        if (type==style.x) {
            u *= 2.0;
        }
        else if (type==style.y) {
            float ox = u.x;
            u.x = -u.y;
            u.y = ox;
        }
        else if (type==style.z) {
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
    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    vec2 vRatio = vec2(ratio, 1.0);

    vec2 u1 = (u_ModelTransform * vec3(pos, 1.0)).xy;
    vec2 split1 = fract(u1)*2.0-1.0;

    vec2 u2 = (u_ModelTransform * vec3(0.0, 0.0, 1.0)).xy;
    vec2 split2 = fract(u2)*2.0-1.0;

    vec4 col = texture2D(u_Tex0, proj0(pos));
    float g = texture2D(u_Tex0, proj0(f1(pos/vRatio, split1, vec4(0.0, 1.0, 2.0, 3.0))*vRatio)).g;
    float b = texture2D(u_Tex0, proj0(f1(pos/vRatio, split2, vec4(0.0, 1.0, 2.0, 3.0))*vRatio)).b;
    return vec4(col.r, g, b, col.a);
}

//vec4 breakg2(vec2 pos, vec2 outPos) {
//    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
//    vec2 vRatio = vec2(ratio, 1.0);
//
//    vec2 u1 = (u_ModelTransform * vec3(pos, 1.0)).xy;
//    vec2 split1 = fract(u1)*2.0-1.0;
//
//    vec4 col = texture2D(u_Tex0, proj0(pos));
////    float r = texture2D(u_Tex0, proj0(f1(pos/vRatio, split1, vec4(0.0, 1.0, 2.0, 3.0))*vRatio)).r;
////    float g = texture2D(u_Tex0, proj0(f1(pos/vRatio, split1, vec4(1.0, 1.0, 3.0, 0.0))*vRatio)).g;
////    float b = texture2D(u_Tex0, proj0(f1(pos/vRatio, split1, vec4(3.0, 1.0, 2.0, 0.0))*vRatio)).b;
//    float r = texture2D(u_Tex0, proj0(f1(pos/vRatio, split1, vec4(0.0, 1.0, 2.0, 3.0))*vRatio)).r;
//    float g = texture2D(u_Tex0, proj0(f1(pos/vRatio, split1, vec4(1.0, 2.0, 3.0, 0.0))*vRatio)).g;
//    float b = texture2D(u_Tex0, proj0(f1(pos/vRatio, split1, vec4(2.0, 3.0, 0.0, 1.0))*vRatio)).b;
//    return vec4(col.r, g, b, col.a);
//}

#include mainWithOutPos(breakg)
