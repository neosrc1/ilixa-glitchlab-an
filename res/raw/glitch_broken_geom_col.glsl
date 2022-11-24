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

vec3 lnorm(vec3 v) {
    float l = v.x+v.y+v.z;
    if (l==0.0) return v;
    else return v/l;
}

mat3 rndMat3(vec2 seed, float k) {
    vec2 rnd = rand2rel(seed);
    vec2 rnd2 = rand2rel(rnd);
    vec2 rnd3 = rand2rel(rnd2);
    return mat3(rnd.x*k, rnd.y*k, 0.0, rnd2.x*k, rnd2.y*k, 0.0, rnd3.x*k, rnd3.y*k, 1.0);
}

vec3 recal(vec3 u) {
    vec3 v = (u+vec3(1.0, 1.0, 1.0))/2.0;
    if (abs(v.x)>1.0) {
        if (v.x>0.0) v.x = fract(v.x);
        else v.x = 2.0+v.x;
    }
    if (abs(v.y)>1.0) {
        if (v.y>0.0) v.y = fract(v.y);
        else v.y = 2.0+v.y;
    }
    return (v*2.0)-vec3(1.0, 1.0, 1.0);
}

mat3 tripleTransform(mat3 m, mat3 transform, int n) {
    for(int i=0; i<n; ++i) {
        m = transform*m;
        m = mat3(recal(m[0]), recal(m[1]), recal(m[2]));
    }
    return m;
}

vec3 transform2(vec3 u, mat3 transform) {
    vec2 split = transform[0].xy;
    vec2 rnd = transform[1].xy;
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
        u *= 2.0;//pow(2.0, intensity);
    }
    return u;
}

mat3 tripleTransform2(mat3 m, mat3 t, int n) {
    for(int i=0; i<n; ++i) {
        m = mat3(transform2(m[0], t), transform2(m[1], t), transform2(m[2], t));
    }
    return m;
}

vec4 breakg(vec2 pos, vec2 outPos) {
    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    vec2 vRatio = vec2(ratio, 1.0);
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);

    vec2 u1 = (u_ModelTransform * vec3(pos, 1.0)).xy;
    vec2 cc = (pos/vRatio+vec2(1.0, 1.0))/2.0;
    vec2 cct = (u_ModelTransform * vec3(cc, 1.0)).xy;
    vec2 split1 = fract(u1)*2.0-1.0;

    vec2 mode = floor(cc);
    vec2 rnd = rand2rel(mode);
    vec2 rnd2 = rand2rel(rnd);
    vec2 rnd3 = rand2rel(rnd2);
    vec2 rnd4 = rand2rel(rnd3);
    vec2 rnd5 = rand2rel(rnd4);
//    mat3 channelMix = mat3(rnd.x, rnd.y, rnd2.x, rnd2.y, rnd3.x, rnd3.y, rnd4.x, rnd4.y, rnd5.x);
//    vec3 rr = lnorm(vec3(rnd.x+0.5, rnd.y+0.5, rnd2.x+0.5));
//    vec3 gg = lnorm(vec3(rnd2.y+0.5, rnd3.x+0.5, rnd3.y+0.5));
//    vec3 bb = lnorm(vec3(rnd4.x+0.5, rnd4.y+0.5, rnd5.x+0.5));
    vec3 rr = normalize(vec3(rnd.x+0.5, rnd.y+0.5, rnd2.x+0.5));
    vec3 gg = normalize(vec3(rnd2.y+0.5, rnd3.x+0.5, rnd3.y+0.5));
    vec3 bb = normalize(vec3(rnd4.x+0.5, rnd4.y+0.5, rnd5.x+0.5));
    mat3 channelMix = mat3(rr, gg, bb);

    mat3 m = mat3(pos.x, pos.y, 1.0, 0.0, 0.0, 1.0, pos.x+1.0, pos.y-1.0, 1.0);
    mat3 tt = tripleTransform2(m, rndMat3(mode, 4.0)*u_ModelTransform, u_Count);
    vec2 tu = tt[0].xy;
    vec2 tv = tt[1].xy;
    vec2 tw = tt[2].xy;
    vec4 col;
    if (length(tu-tv)>intensity) {
        vec4 a = texture2D(u_Tex0, proj0(vec2(-0.99, tu.y)));
        vec4 b = texture2D(u_Tex0, proj0(vec2(0.99, tu.y)));
        col = mix(a, b, fract((tu.x+1.0)/2.0));
    }
    else if (length(tu-tw)>intensity) {
        col = texture2D(u_Tex0, proj0(pos));
        float g = floor((col.r+col.g+col.b)/3.0+0.5);
        col = vec4(g, g, g, col.a);
    }
    else {
        col = texture2D(u_Tex0, proj0(pos));
    }
    vec4 outCol = col;

//    vec4 col = texture2D(u_Tex0, proj0((rndMat3(mode, 4.0)*u_ModelTransform*vec3(pos, 1.0)).xy));
//    vec4 outCol = vec4(channelMix*col.rgb, col.a);
//    vec4 outCol = vec4(dot(rr, col.rgb), dot(gg, col.rgb), dot(bb, col.rgb), col.a);

    float k = getLocus(outPos, outCol);
    if (k==1.0) return outCol;
    else return mix(texture2D(u_Tex0, proj0(outPos)), outCol, k);
}

#include mainWithOutPos(breakg)
