precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Dampening;
uniform float u_Variability;
uniform float u_Seed;


vec4 inStripes(vec2 u) {
    int index = floor(u.y/2.0);
//    float var = u_Variability*0.01 * (rand2(vec2(index, index)).x-0.5) * 2.0;
    float var = u_Variability*0.01 * (rand2relSeeded(vec2(index, index)).x, u_Seed) * 2.0;
    float inside = (fmod(u.y, 2.0) < 1.0 + var) ? 1.0 : 0.0;
    return vec4(0.0, 0.0, 0.0, inside);
}

vec4 shape(vec2 pos, vec2 outPos) {
    float dampening = 1.0;
    if (u_Dampening<0.0) dampening = 1.0 + u_Dampening*0.01 * min(1.0, length(pos));
    else if (u_Dampening>0.0) dampening = 1.0 - u_Dampening*0.01 * (1.0-min(1.0, length(pos)));

    vec2 shapePos = (u_ModelTransform * vec3(pos, 1.0)).xy;
    vec4 inside = inStripes(shapePos);

    vec2 u;
    if (inside.w==0.0 && dampening==1.0) {
        u = pos;
    }
    else if (inside.w==1.0 && dampening==1.0) {
        u = (u_ViewTransform * vec3(pos, 1.0)).xy;
    }
    else {
        u = mix(pos, (u_ViewTransform * vec3(pos, 1.0)).xy, inside.w * dampening);
    }

    return texture2D(u_Tex0, proj0(u));

}

void main() {
    vec4 outc;

    if (u_Antialias==4) {
        vec2 outPos00 = (v_OutCoordinate * u_Tex0Dim + vec2(-0.333, -0.333)) / u_Tex0Dim;
        vec2 outPos10 = (v_OutCoordinate * u_Tex0Dim + vec2(0.333, -0.333)) / u_Tex0Dim;
        vec2 outPos01 = (v_OutCoordinate * u_Tex0Dim + vec2(-0.333, 0.333)) / u_Tex0Dim;
        vec2 outPos11 = (v_OutCoordinate * u_Tex0Dim + vec2(0.333, 0.333)) / u_Tex0Dim;

        outc = (shape(outPos00, outPos00) +
            shape(outPos10, outPos10) +
            shape(outPos01, outPos01) +
            shape(outPos11, outPos11) ) * 0.25;
    }
    else {
        outc = shape(v_OutCoordinate, v_OutCoordinate);
    }

    gl_FragColor = blend(outc, v_OutCoordinate);
}