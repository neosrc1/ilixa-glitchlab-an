precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform int u_Iterations;
uniform int u_Count;
uniform float u_Intensity;
uniform float u_Power;
uniform float u_Thickness;
uniform vec4 u_Color1;

vec2 getDir(float angle) {
    return vec2(sin(angle), cos(angle));
}

vec4 kifs(vec2 pos, vec2 outPos) {
    pos *= 1.25;
    pos.x = abs(pos.x);
//    float ang = 5.0/6.0*M_PI + u_ModelTransform[2][1];
    float ang = 5.0/6.0*M_PI;// * u_ModelTransform[0][0];
    pos.y += tan(ang)*0.5;
    vec2 n = getDir(ang);
    float d = dot(pos-vec2(0.5, 0.0), n);
    pos -= n*max(0.0, d)*2.0;

    float ang1 = 2.0/3.0*M_PI + u_ModelTransform[2][0];
    vec2 n1 = getDir(ang1);
    float ang2 = 2.0/3.0*M_PI + u_ModelTransform[2][1];
    vec2 n2 = getDir(ang2);
    float scale = 1.0;
    pos.x += 0.5;
    for(int i=0; i<u_Count; ++i) {
        pos *= 3.0* u_ModelTransform[0][0];
        scale *= 3.0* u_ModelTransform[0][0];
        pos.x -= 1.5;

        pos.x = abs(pos.x);
        pos.x -= 0.5;
        if ((i/2)*2==i) pos -= n1*min(0.0, dot(pos, n1))*2.0;
        else pos -= n2*min(0.0, dot(pos, n2))*2.0;
    }

    d = length(pos-vec2(clamp(pos.x, -1.0, 1.0), 0.0));

    pos /= scale;
    float k = d/scale<u_Thickness*0.001 ? 1.0 : 0.0; //smoothstep(u_Thickness*0.01, 0.0, d/scale);
    vec4 col = texture2D(u_Tex0, proj0(pos));
    if (k>0.0) {
        return vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a);
    }
    else {
        return col;
    }
}

#include mainWithOutPos(kifs)
