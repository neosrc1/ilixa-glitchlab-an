precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include smoothrandom
#include locuswithcolor_nodep

uniform int u_Count;
uniform float u_Balance;
uniform float u_Intensity;
uniform float u_Variability;
uniform float u_Phase;
uniform float u_Phase2;
uniform float u_Seed;
uniform mat3 u_InverseModelTransform;
uniform mat3 u_ModelTransform2;
uniform mat3 u_InverseModelTransform2;



vec4 wave(vec2 pos, vec2 outPos) {
    vec2 u = pos;

    float intensity = getMaskedParameter(u_Intensity, outPos)*0.01;
    intensity = u_LocusMode>=6 ? intensity : intensity * getLocus(pos, vec4(0.0, 0.0, 0.0, 0.0), vec4(0.0, 0.0, 0.0, 0.0));

    mat3 rotMat = mat3(cos(u_Phase), sin(u_Phase), 0.0, -sin(u_Phase), cos(u_Phase), 0.0, 0.0, 0.0, 1.0);
    /*mat3 t1 = u_ModelTransform * ts;
    mat3 invt1 = invts * u_InverseModelTransform;
    mat3 t2 = u_ModelTransform2 * ts;
    mat3 invt2 = invts * u_InverseModelTransform2;*/

    mat3 invTransf = u_InverseModelTransform;
    mat3 transf = u_ModelTransform;
    vec2 bTranslate = (u_Balance > 0.0 ? u_Balance*0.01 : 0.0) * vec2(cos(u_Balance*0.1), sin(-u_Balance*0.1));

    for(int j=0; j<u_Count; ++j) {
        vec2 translate = bTranslate*float(j); //u_Balance > 0.0 ? u_Balance*0.005*float(j) : 0.0;
        float scale = u_Balance < 0.0 ? pow(0.999, abs(u_Balance)*float(j)) : 1.0;
        mat3 ts = mat3(scale, 0.0, 0.0, 0.0, scale, 0.0, 0.0, 0.0, 1.0);
        mat3 invts = mat3(1.0/scale, 0.0, 0.0, 0.0, 1.0/scale, 0.0, 0.0, 0.0, 1.0);
        mat3 tt = mat3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, translate.x, translate.y, 1.0);
        mat3 invtt = mat3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, -translate.x, -translate.y, 1.0);
        mat3 t1 = ts* u_ModelTransform * tt;
        mat3 invt1 = invtt * u_InverseModelTransform * invts;
        mat3 t2 = ts * u_ModelTransform2 * tt;
        mat3 invt2 = invtt * u_InverseModelTransform2 * invts;

        mat3 invTransf = (j==(j/2)*2) ? invt1 : invt2;
        //        mat3 invTransf = u_InverseModelTransform;
        u = (invTransf * vec3(u, 1.0)).xy;

        float d = u.x;

        float N = 4.0;
        float xx = u.x/N;
        float i = floor(xx);
        float di = xx - i;

        vec2 rnd = rand2relSeeded(vec2(i, i), u_Seed);
        vec2 rnd2;
        float var = rnd.x;
        if (di<0.5) {
            rnd2 = rand2relSeeded(vec2(i-1.0, i-1.0), u_Seed);
            di = 0.5-di;
        }
        else {
            rnd2 = rand2relSeeded(vec2(i+1.0, i+1.0), u_Seed);
            di = di-0.5;
        }
        var = mix(var, rnd2.x, di*di*2.0);

        float magnitude = intensity * (1.0 + ((u_Variability*0.1) * (var)*2.0));
        float dy =  sin(xx*M_PI) * magnitude;

        mat3 transf = (j==(j/2)*2) ? t1 : t2;
        //        mat3 transf = u_ModelTransform;
        u = (transf * vec3(u.x, u.y+dy, 1.0)).xy;
        //        u = (transf * vec3(u.x, u.y, 1.0)).xy;

        invTransf = invTransf * 0.9;
        transf = rotMat / 0.9;
    }

    vec4 outCol = texture2D(u_Tex0, proj0(u));
    if (u_LocusMode>=6) {
        vec4 col = texture2D(u_Tex0, proj0(pos));
        float locIntensity = getLocus(pos, col, outCol);
        return mix(col, outCol, locIntensity);
    }
    else {
        return outCol;
    }
}
/*
vec4 wave(vec2 pos, vec2 outPos) {
    vec2 u = pos;

    float intensity = getMaskedParameter(u_Intensity, outPos)*0.01;
    mat3 rotMat = mat3(cos(u_Phase), sin(u_Phase), 0.0, -sin(u_Phase), cos(u_Phase), 0.0, 0.0, 0.0, 1.0);
    mat3 invRotMat = mat3(cos(-u_Phase), sin(-u_Phase), 0.0, -sin(-u_Phase), cos(-u_Phase), 0.0, 0.0, 0.0, 1.0);

    mat3 rotMat2 = mat3(cos(u_Phase2), sin(u_Phase2), 0.0, -sin(u_Phase2), cos(u_Phase2), 0.0, 0.0, 0.0, 1.0);
    mat3 invRotMat2 = mat3(cos(-u_Phase2), sin(-u_Phase2), 0.0, -sin(-u_Phase2), cos(-u_Phase2), 0.0, 0.0, 0.0, 1.0);

    mat3 invTransf = u_InverseModelTransform;
    mat3 transf = u_ModelTransform;

    for(int j=0; j<u_Count; ++j) {
        mat3 invTransf = (j==(j/2)*2) ? u_InverseModelTransform : u_InverseModelTransform2;
//        mat3 invTransf = u_InverseModelTransform;
        u = (invTransf * vec3(u, 1.0)).xy;

        float d = u.x;

        float N = 4.0;
        float xx = u.x/N;
        float i = floor(xx);
        float di = xx - i;

        vec2 rnd = rand2relSeeded(vec2(i, i), u_Seed);
        vec2 rnd2;
        float var = rnd.x;
        if (di<0.5) {
            rnd2 = rand2relSeeded(vec2(i-1.0, i-1.0), u_Seed);
            di = 0.5-di;
        }
        else {
            rnd2 = rand2relSeeded(vec2(i+1.0, i+1.0), u_Seed);
            di = di-0.5;
        }
        var = mix(var, rnd2.x, di*di*2.0);

        float magnitude = intensity * (1.0 + ((u_Variability*0.1) * (var)*2.0));
        float dy =  sin(xx*M_PI) * magnitude;

        mat3 transf = (j==(j/2)*2) ? u_ModelTransform : u_ModelTransform2;
//        mat3 transf = u_ModelTransform;
        u = (transf * vec3(u.x, u.y+dy, 1.0)).xy;
//        u = (transf * vec3(u.x, u.y, 1.0)).xy;

        invTransf = invTransf * 0.9;
        transf = rotMat / 0.9;

//        if (j==(j/2)*2) {
//            invTransf = invTransf * invRotMat;
//            transf = rotMat * transf;
//        }
//        else {
//            invTransf = invTransf * invRotMat2;
//            transf = rotMat2 * transf;
//        }
    }

    return texture2D(u_Tex0, proj0(u));
}
*/
#include mainWithOutPos(wave)
