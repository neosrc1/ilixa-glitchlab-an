precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random


uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform float u_Hardness;
uniform float u_Variability;
uniform float u_ColorVariability;
uniform float u_Seed;
uniform float u_Balance;
uniform float u_Intensity;
uniform float u_Dampening;


vec4 metaballs(vec2 pos, vec2 outPos) {

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    vec2 u2 = u*0.3;

    vec2 p = floor(u+0.5);
    vec2 p2 = floor(u2+0.5);

    float N = 4.0;
    float t = 0.0;
    float tk2 = 0.0;
    vec3 tc = vec3(0.0, 0.0, 0.0);
    for(float j=-N; j<=N; ++j) {
        for(float i=-N; i<=N; ++i) {
            vec2 q = p+vec2(i, j);
            vec2 q2 = p2+vec2(i, j);
			vec2 rnd = rand2relSeeded(q, u_Seed);
			vec2 rnd2 = rand2relSeeded(q2, u_Seed);

            vec3 col = u_Color2.rgb + vec3(rnd2.x, rnd2.y, fract((rnd2.x+rnd2.y)*50.0)-0.5)*u_ColorVariability*0.02;

            vec2 c = q+rnd*u_Variability*0.02;
            vec2 c2 = q2+rnd2*2.0;

            vec2 d = u-c;
            vec2 d2 = u2-c2;

            float k2 = 1.0/(0.001+dot(d2, d2));
            float k = 1.0/(u_Dampening*0.01+smoothstep(0.0, 3.0, length(d)));

            t += k;
            tk2 += k2;
            tc += col*k2;
        }
    }

    // good simple:
    //float k = smoothstep(-0.50, -0.455, sin(t*0.05));//t*0.0055 > 1.0 ? 1.0 : 0.0;
    float a = mix(-2.0, u_Balance*0.01, u_Hardness*0.01);
    float b = mix(2.0, u_Balance*0.01, u_Hardness*0.01);
    float k = smoothstep(a, b, sin(t*u_Intensity*0.02));//t*0.0055 > 1.0 ? 1.0 : 0.0;
    tc /= tk2;

    return mix(u_Color1, vec4(tc, u_Color2.a), k);

}

#include mainWithOutPos(metaballs)
