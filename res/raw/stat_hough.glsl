precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math

vec4 hough(vec2 pos, vec2 outPos) {
    float ratio = u_Tex0Dim.x / u_Tex0Dim.y;
    float angle = pos.x/ratio * M_PI;
    float diag = length(vec2(ratio, 1.0));
    float d = min(1.0, ratio)* pos.y;
//    float d = diag * pos.y;
    float pixel = 2.0 / u_Tex0Dim.y * 4.0;
    float ca = cos(angle);
    float sa = sin(angle);
    vec2 a = d*vec2(sa, -ca);
//    a.x = fmod(a.x+ratio, 2.0*ratio)-ratio;
//    a.y = fmod(a.y+1.0, 2.0)-1.0;
    vec2 dir = vec2(ca, sa);
    
    float k1 = -10000.0;
    float k2 = 10000.0;
    float k;
    if (dir.x!=0.0) {
        k = (-ratio-a.x)/dir.x;
        if (k<0.0) k1 = max(k1, k);
        else k2 = min(k2, k);
        k = (ratio-a.x)/dir.x;
        if (k<0.0) k1 = max(k1, k);
        else k2 = min(k2, k);
    }
    if (dir.y!=0.0) {
        k = (-1.0-a.y)/dir.y;
        if (k<0.0) k1 = max(k1, k);
        else k2 = min(k2, k);
        k = (1.0-a.y)/dir.y;
        if (k<0.0) k1 = max(k1, k);
        else k2 = min(k2, k);
    }    

//    return texture2D(u_Tex0, proj0(a));
    vec4 sum = vec4(0.0, 0.0, 0.0, 0.0);
    float N = 0.0;
    k = k1;
    float dk = (k2-k1);
//    return vec4(vec3(dk ,dk, dk)*0.3, 1.0);

    if (k2-k1<5000.0*pixel)
    while (k<=k2) {
        sum += texture2D(u_Tex0, proj0(a+k*dir));
        N += 1.0;
        k += pixel;
    }
    return N>0.0 ? sum/N : vec4(0.0, 0.0, 0.0, 1.0);
}

#include mainWithOutPos(hough)
