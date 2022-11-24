precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include smoothrandom
uniform float u_Dispersion;

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
//    return vec2(mix(a.x, b.x, smoothstep(0.0, 1.0, k)), mix(a.y, b.y, smoothstep(0.0, 1.0, k)));
    return mix(a, b, k);
}

vec4 displace(vec2 pos, vec2 outPos) {
    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy; //transform(pos, center, scale);

    float v = getMaskedParameter(u_Intensity, outPos)*0.04;

    vec2 c = floor(t);
    vec2 r = fract(t);
    for(float j = -3.0; j <= 3.0; ++j) {
        for(float i = -3.0; i <= 3.0; ++i) {
            /* No good. What may work:
                compute if t is in the projected quadrilatere of the 4 corners of tile f -
                this may be resolution of a 2 line equation system yielding an x and a y between 0 and 1 (otherwise the point is not in the proj)
                if in, f + (x,y) is the anterior point.
                Unsure how this is going to work with concave quadrilateres */

            vec2 f = c + vec2(i, j);
            vec2 delta00 = rand2relSeeded(f, u_Seed) * v;
            vec2 delta10 = rand2relSeeded(f+vec2(1.0, 0.0), u_Seed) * v;
            vec2 delta01 = rand2relSeeded(f+vec2(0.0, 1.0), u_Seed) * v;
            vec2 delta11 = rand2relSeeded(f+vec2(1.0, 1.0), u_Seed) * v;
            vec2 delta = sstep(sstep(delta00, delta10, r.x), sstep(delta01, delta11, r.x), r.y);
            vec2 anterior = (t-delta);
            if (floor(anterior)==f) {
                vec2 v = (u_InverseModelTransform * vec3(anterior, 1.0)).xy;
                return texture2D(u_Tex0, proj0(v));
            }
        }
    }
    return vec4(0.0, 0.0, 0.0, 1.0);

//        vec4 dcol = vec4(delta.x, delta.y, 0.5, 1.0);
//        vec4 outColor = mix(texture2D(u_Tex0, proj0(pos+delta)), dcol, 0.0);
//
//        return outColor;
//    if (u_Dispersion==0.0) {
//    }
//    else {
//        float wStep = 0.05;
//        vec4 totalColor = vec4(0.0, 0.0, 0.0, 0.0);
//        vec4 totalWeight = vec4(0.0, 0.0, 0.0, 0.0);
//        float dispersion = u_Dispersion*0.01;
//            vec2 delta = sstep(sstep(delta00, delta10, r.x), sstep(delta01, delta11, r.x), r.y);
//        for(float w=-1.0; w<=1.0; w+=wStep) {
//            vec4 dcol = vec4(delta.x, delta.y, 0.5, 1.0);
//            vec4 outColor = mix(texture2D(u_Tex0, proj0(pos+(1.0+w*dispersion)*delta)), dcol, 0.0);
//            vec4 weight = getRGBWeights(w);
//            totalColor += weight*outColor;
//            totalWeight += weight;
//        }
//        return totalColor / totalWeight;
//    }

}

#include mainWithOutPos(displace)
