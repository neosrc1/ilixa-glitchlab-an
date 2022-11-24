precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include hsl
#include locuswithcolor

uniform int u_Count;
uniform float u_Intensity;


vec2 f2(vec2 u, vec2 split, vec2 s, float intensity) {
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
            u.x = pow(u.x, rnd.y);// not working on Tab S2
            u.y = pow(u.y, rnd.x);
            //            u.x = sign(u.x)*pow(abs(u.x), rnd.y);// not working on Tab S2
            //            u.y = sign(u.y)*pow(abs(u.y), rnd.x);
            //            u.x = u.x*u.x;//u.x*2.0;
            //            u.y = u.y*u.y;
        }

        if (max(abs(u.x), abs(u.y))>1.5) {
            u *= pow(2.0, intensity);
        }

    }
    return u;
}


vec4 breakg3(vec2 pos, vec2 outPos) {
    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    vec2 vRatio = vec2(ratio, 1.0);
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);

    vec2 u1 = (u_ModelTransform * vec3(pos, 1.0)).xy;
    vec2 split1 = fract(u1)*2.0-1.0;

    vec4 col = texture2D(u_Tex0, proj0(pos));
//    float r = texture2D(u_Tex0, proj0(f1(pos/vRatio, split1, vec4(0.0, 1.0, 2.0, 3.0))*vRatio)).r;
//    float g = texture2D(u_Tex0, proj0(f1(pos/vRatio, split1, vec4(1.0, 1.0, 3.0, 0.0))*vRatio)).g;
//    float b = texture2D(u_Tex0, proj0(f1(pos/vRatio, split1, vec4(3.0, 1.0, 2.0, 0.0))*vRatio)).b;
    vec2 px = f2(pos/vRatio, split1, floor(u1), intensity)*vRatio;
    vec2 py = f2(pos/vRatio, split1, floor(u1)-vec2(1.0, 1.0), intensity)*vRatio;
    vec2 pz = f2(pos/vRatio, split1, floor(u1)+vec2(2.0, 0.0), intensity)*vRatio;
    vec4 outCol;
    if (length(px-py) > length(py-pz)*(intensity+1.0)) {
        float r = texture2D(u_Tex0, proj0(px)).r;
        float g = texture2D(u_Tex0, proj0(py)).g;
        float b = texture2D(u_Tex0, proj0(pz)).b;
        outCol = vec4(col.r, g, b, col.a);
    }
    else {
        vec4 a = texture2D(u_Tex0, proj0(vec2(px.x, -0.99)));
        vec4 b = texture2D(u_Tex0, proj0(vec2(px.x, 0.99)));
        outCol = mix(a, b, (px.y+1.0)/2.0);
    }

    float k = getLocus(pos, outCol);
    if (k==1.0) return outCol;
    else return mix(texture2D(u_Tex0, proj0(pos)), outCol, k);
}

vec4 breakg4(vec2 pos, vec2 outPos) {
    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    vec2 vRatio = vec2(ratio, 1.0);
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);

    vec2 u1 = (u_ModelTransform * vec3(pos, 1.0)).xy;
    vec2 split1 = fract(u1)*2.0-1.0;

    vec4 col = texture2D(u_Tex0, proj0(pos));
//    float r = texture2D(u_Tex0, proj0(f1(pos/vRatio, split1, vec4(0.0, 1.0, 2.0, 3.0))*vRatio)).r;
//    float g = texture2D(u_Tex0, proj0(f1(pos/vRatio, split1, vec4(1.0, 1.0, 3.0, 0.0))*vRatio)).g;
//    float b = texture2D(u_Tex0, proj0(f1(pos/vRatio, split1, vec4(3.0, 1.0, 2.0, 0.0))*vRatio)).b;
    vec2 px = f2(pos/vRatio, split1, floor(u1), intensity)*vRatio;
    vec2 py = f2(pos/vRatio, split1, floor(u1)-vec2(1.0, 1.0), intensity)*vRatio;
    vec2 pz = f2(pos/vRatio, split1, floor(u1)+vec2(2.0, 0.0), intensity)*vRatio;
    vec4 outCol;
    if (length(px-py) > length(py-pz)*(intensity*2.0+1.0)) {
        float r = texture2D(u_Tex0, proj0(px)).r;
        float g = texture2D(u_Tex0, proj0(py)).g;
        float b = texture2D(u_Tex0, proj0(pz)).b;
        outCol = vec4(col.r, g, b, col.a);
    }
    else if (length(px-py) > length(px-pz)*(intensity*2.0+1.0)) {
        vec4 a = texture2D(u_Tex0, proj0(vec2(-0.99, px.y)));
        vec4 b = texture2D(u_Tex0, proj0(vec2(0.99, px.y)));
        outCol = mix(a, b, fract((px.x+1.0)/2.0));
    }
    else {
        vec4 a = texture2D(u_Tex0, proj0(vec2(px.x, -0.99)));
        vec4 b = texture2D(u_Tex0, proj0(vec2(px.x, 0.99)));
        outCol = mix(a, b, fract((px.y+1.0)/2.0));
    }

    float k = getLocus(outPos, outCol);
    if (k==1.0) return outCol;
    else return mix(texture2D(u_Tex0, proj0(outPos)), outCol, k);
}

#include mainWithOutPos(breakg4)
