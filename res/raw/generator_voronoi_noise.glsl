precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform int u_Count;
uniform float u_PosterizeCount;
uniform float u_Variability;

float voronoi_noise_at(vec2 u, int count) {
    float noise = 0.0;
    float amplitude = 0.6;

    for(int k=0; k<count; ++k) {
        vec2 v = floor(vec2(u.x+0.5, u.y+0.5));
        float closest = 10000.0;
        for(int j=-2; j<=2; ++j) {
            for(int i=-2; i<=2; ++i) {
                vec2 point = vec2(v.x+float(i), v.y+float(j));
                vec2 displace = (rand2(point) - vec2(0.5, 0.5))*u_Variability*0.02;
                float distance = length(point+displace - u);
                if (distance < closest) {
                    closest = distance;
                }
            }
        }
        noise += amplitude * closest;
        amplitude *= 0.5;
        u = u*2.0 + vec2(3.34, 2.55);
    }

    return noise;
}

//float voronoi_noise2_at(vec2 u, int count) {
//    float noise = 0.0;
//    float amplitude = 0.03;
//
//    for(int k=0; k<count; ++k) {
//        vec2 v = floor(vec2(u.x+0.5, u.y+0.5));
//        for(int j=-2; j<=2; ++j) {
//            for(int i=-2; i<=2; ++i) {
//                vec2 point = vec2(v.x+float(i), v.y+float(j));
//                vec2 displace = (rand2(point) - vec2(0.5, 0.5))*u_Variability*0.02;
//                float distance = length(point+displace - u);
//                noise += amplitude*min(10.0, 1.0/(distance*distance));
//            }
//        }
//        amplitude *= 0.5;
//        u = u*2.0;
//    }
//
//    return noise;
//}


vec4 vornoi_noise(vec2 pos, vec2 outPos) {

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float k = clamp(voronoi_noise_at(u, u_Count), 0.0, 1.0);
    if (u_PosterizeCount<256.0) {
        k = min(floor(k*u_PosterizeCount) / (u_PosterizeCount-1.0), 1.0);
    }

    return mix(u_Color1, u_Color2, k);

}

#include mainWithOutPos(vornoi_noise)
