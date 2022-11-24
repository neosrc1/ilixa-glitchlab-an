precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include smoothrandom
#include hsl
#include tex(1)

uniform float u_Intensity;
uniform float u_Seed;
uniform mat3 u_InverseModelTransform;

vec4 getRGBWeights(float w) {
    return vec4(
        max(0.0, -w),
        max(0.0, 1.0-abs(w)),
        max(0.0, w),
        1.0
    );
}

vec2 sstep(vec2 a, vec2 b, float k) {
    return vec2(mix(a.x, b.x, smoothstep(0.0, 1.0, k)), mix(a.y, b.y, smoothstep(0.0, 1.0, k)));
}

vec4 displace(vec2 pos, vec2 outPos) {
    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy; //transform(pos, center, scale);

    vec2 f = floor(t);
    vec2 r = fract(t);
    float v = 2.0;
    vec2 delta00 = rand2relSeeded(f, u_Seed) * v;
    vec2 delta10 = rand2relSeeded(f+vec2(1.0, 0.0), u_Seed) * v;
    vec2 delta01 = rand2relSeeded(f+vec2(0.0, 1.0), u_Seed) * v;
    vec2 delta11 = rand2relSeeded(f+vec2(1.0, 1.0), u_Seed) * v;

    float wStep = 0.05;
    vec4 totalColor = vec4(0.0, 0.0, 0.0, 0.0);
    vec4 totalWeight = vec4(0.0, 0.0, 0.0, 0.0);
    float dispersion = getMaskedParameter(u_Intensity, outPos)*0.01;
    vec2 delta = sstep(sstep(delta00, delta10, r.x), sstep(delta01, delta11, r.x), r.y);
    if (u_Tex1Transform[2][2]==0.0) {
        for(float w=-1.0; w<=1.0; w+=wStep) {
            vec4 dcol = vec4(delta.x, delta.y, 0.5, 1.0);
            vec4 outColor = mix(texture2D(u_Tex0, proj0(pos+(w*dispersion)*delta)), dcol, 0.0);
            vec4 weight = getRGBWeights(w);
            totalColor += weight*outColor;
            totalWeight += weight;
        }
    }
    else {
        float ratio = u_Tex1Dim.x/u_Tex1Dim.y;
        for(float w=-1.0; w<=1.0; w+=wStep) {
            vec4 dcol = vec4(delta.x, delta.y, 0.5, 1.0);
            vec4 outColor = mix(texture2D(u_Tex0, proj0(pos+(w*dispersion)*delta)), dcol, 0.0);
            vec4 weight = texture2D(u_Tex1, proj1(vec2(ratio*w, 0.0)));
            totalColor += weight*outColor;
            totalWeight += weight;
        }
    }

    return totalColor / totalWeight;

}

#include mainWithOutPos(displace)
