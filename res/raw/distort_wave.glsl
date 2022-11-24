precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include smoothrandom

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Variability;
uniform mat3 u_InverseModelTransform;



vec4 wave(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = u.x;

    float N = 4.0;
    float xx = u.x/N;
    float i = floor(xx);
    float di = xx - i;

    vec2 rnd = rand2(vec2(i, i));
    vec2 rnd2;
    float var = rnd.x;
    if (di<0.5) {
        rnd2 = rand2(vec2(i-1.0, i-1.0));
        di = 0.5-di;
    }
    else {
        rnd2 = rand2(vec2(i+1.0, i+1.0));
        di = di-0.5;
    }
    var = mix(var, rnd2.x, di*di*2.0);

    float intensity = getMaskedParameter(u_Intensity, outPos)*0.1;
    float magnitude = intensity * (1.0 + ((u_Variability*0.01) * (var-0.5)*2.0));
    float dy =  sin(xx*M_PI) * magnitude;

    vec2 coord = (u_ModelTransform * vec3(u.x, u.y+dy, 1.0)).xy;
    return texture2D(u_Tex0, proj0(coord));
}

#include mainWithOutPos(wave)
