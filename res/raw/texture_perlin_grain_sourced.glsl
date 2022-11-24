precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include smoothrandom
#include tex(1)

uniform int u_Count;
uniform float u_Intensity;

vec2 window(vec2 u) {
    return u; // could be used to prevent repeating patterns though this might cause problems due to linear interpolation...
}

float getNoise(vec2 u) {
    vec2 v = (proj1(u) + 1.0)/2.0;
    vec2 r = fract(v);
    vec2 w = (floor(v-r)/u_Tex1Dim);
    vec2 z = v+w;
    vec4 offsetCol = texture2D(u_Tex1, z);
    vec2 offset = floor(offsetCol.xy*(u_Tex1Dim-1.0)+0.5) / (u_Tex1Dim);

    vec4 color = texture2D(u_Tex1, proj1(u) + offset.xy);//((offset.xy)*2.0-1.0));
    return (color.r + color.g + color.b)/3.0;
}

float getNoise2(vec2 v) {
    vec2 r = fract(v);
    vec2 w = (floor(v-r)/u_Tex1Dim);
    vec2 z = v+w;
    vec4 offsetCol = texture2D(u_Tex1, z);
    vec2 offset = floor(offsetCol.xy*(u_Tex1Dim-1.0)+0.5) / (u_Tex1Dim);

    vec4 color = texture2D(u_Tex1, v + offset.xy);//((offset.xy)*2.0-1.0));
    return (color.r + color.g + color.b)/3.0;
}

float getInterpolatedNoise(vec2 u) {
    vec2 v = (proj1(u) + 1.0)/2.0 * u_Tex1Dim;
    vec2 v00 = floor(v);
    vec2 v11 = ceil(v);
    vec2 v01 = vec2(v00.x, v11.y);
    vec2 v10 = vec2(v11.x, v00.y);
    vec2 k = v-v00;
    float n00 = getNoise2(v00 / u_Tex1Dim);
    float n10 = getNoise2(v10 / u_Tex1Dim);
    float n01 = getNoise2(v01 / u_Tex1Dim);
    float n11 = getNoise2(v11 / u_Tex1Dim);
    return mix(
        mix(n00, n10, k.x),
        mix(n01, n11, k.x),
        k.y );
}

//vec4 getNoise2(vec2 u) {
//    vec2 v = (proj1(u) + 1.0)/2.0;
//    vec2 r = fract(v);
//    vec2 w = (floor(v-r)/u_Tex1Dim);
//    vec2 z = v+w;
//    vec4 offsetCol = texture2D(u_Tex1, z);
//    vec2 offset = floor(offsetCol.xy*(u_Tex1Dim-1.0)+0.5) / (u_Tex1Dim);
//
//    vec4 color = texture2D(u_Tex1, proj1(u) + offset.xy);//((offset.xy)*2.0-1.0));
//    return vec4(color.r, offsetCol.x, texture2D(u_Tex1, v).r, 1.0);
//}

float perlin(vec2 u, int count) {
    float s = 1.0;
    float k = 0.5;
    float total = 0.0;
    vec3 uu = vec3(u, 1.0);

    mat3 pt = mat3(0.958851077208406, 1.7551651237807455, 0.0, -1.7551651237807455, 0.958851077208406, 0.0, 0.0, 0.0, 1.0);
    for(int i = 0; i<count; ++i) {
//        vec4 color = texture2D(u_Tex1, proj1(window(uu.xy)));
        float color = getInterpolatedNoise(uu.xy);
        total += color*k;
        k *= 0.5;
        uu = pt*uu;
        //s *= 2.2;
    }

    return total;
}

vec4 grain(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float intensity = getMaskedParameter(u_Intensity, outPos);

    vec4 color = texture2D(u_Tex0, proj0(pos));
    if (u_Intensity > 0.0) {
        float lumNoise = perlin(t, u_Count)-0.5;
        color.rgb = color.rgb * (1.0 + intensity*0.05*lumNoise);
    }
    else if (u_Intensity < 0.0) {
        float lumNoise = perlin(t, u_Count)-0.5;
        color.rgb -= intensity*0.05*lumNoise;
    }

    return color;
}

#include mainWithOutPos(grain)
