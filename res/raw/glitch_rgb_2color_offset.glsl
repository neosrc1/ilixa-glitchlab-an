precision highp float;
precision highp int;

#include commonvar
#include commonfun

uniform float u_Dampening;
uniform float u_Blur;
uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform mat3 u_ModelTransform1;
uniform mat3 u_ModelTransform2;

vec2 getOffsetPos(mat3 transform, vec2 pos) {
    vec2 tPos = (transform*vec3(pos, 1.0)).xy;
    float dist = length(pos);
    if (dist<1.0) {
        tPos = mix(pos, tPos, 1.0-u_Dampening*0.01*(1.0-dist*dist));
    }
    return tPos;
}

vec4 offset(vec2 pos) {
    if (u_Blur!=0.0) {
//        vec2 p1 = proj0(getOffsetPos(u_ModelTransform1, pos));
//        vec2 p2 = proj0(getOffsetPos(u_ModelTransform2, pos));
//        vec4 total = vec4(0.0, 0.0, 0.0, 0.0);
////        vec4 totalWeight = vec4(0.0, 0.0, 0.0, 0.0);
//        float totalWeight = 0.0;
//        float N = 100.0;
//        for(float i=0.0; i<=N; i+=1.0) {
//            float k = i/N;
//            vec4 color = mix(u_Color1, u_Color2, k);
//            vec2 p = mix(p1, p2, k);
//            float weight = pow(abs(0.5-k)*2.0, pow(u_Blur*0.02, -4.0));
//            totalWeight += weight;
//            vec4 sample = texture2D(u_Tex0, p);
//            total.rgb += color.rgb*sample.rgb * weight;
//            total.a += sample.a * weight;
//        }
//        return total/(totalWeight*0.5);

        vec2 pp = proj0(pos);
        vec2 p1 = proj0(getOffsetPos(u_ModelTransform1, pos));
        vec2 p2 = proj0(getOffsetPos(u_ModelTransform2, pos));
        vec4 total = vec4(0.0, 0.0, 0.0, 0.0);
//        vec4 totalWeight = vec4(0.0, 0.0, 0.0, 0.0);
        float totalWeight = 0.0;
        float N = 100.0;
        for(float i=0.0; i<=N; i+=1.0) {
            float k = i/N;
            vec4 color1 = mix(vec4(1.0, 1.0, 1.0, 1.0), u_Color1, k);
            vec4 color2 = mix(vec4(1.0, 1.0, 1.0, 1.0), u_Color2, k);
            vec2 q1 = mix(pp, p1, k);
            vec2 q2 = mix(pp, p2, k);
            float weight = pow(k, pow(u_Blur*0.02, -4.0));
            totalWeight += weight;

            vec4 sample1 = texture2D(u_Tex0, q1);
            total.rgb += color1.rgb*sample1.rgb * weight;
            total.a += sample1.a * weight;

            vec4 sample2 = texture2D(u_Tex0, q2);
            total.rgb += color2.rgb*sample2.rgb * weight;
            total.a += sample2.a * weight;
        }
        return total/(totalWeight*mix(1.0, 1.5, u_Blur*0.01));
    }
    else {
        vec4 c1 = texture2D(u_Tex0, proj0(getOffsetPos(u_ModelTransform1, pos)));
        vec4 c2 = texture2D(u_Tex0, proj0(getOffsetPos(u_ModelTransform2, pos)));
        return vec4((c1*u_Color1 + c2*u_Color2).rgb, (c1.a+c2.a)*0.5);
    }
}

#include mainPerPixel(offset)
