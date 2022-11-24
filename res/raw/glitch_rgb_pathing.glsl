precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include locuswithcolor

uniform float u_Intensity;
uniform int u_Count;
uniform float u_Phase;

vec4 pick(vec2 pos, vec2 outPos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));
    vec2 dirR = vec2(cos(u_Phase), sin(u_Phase));
    vec2 dirG = vec2(cos(M_2PI/3.0+u_Phase), sin(M_2PI/3.0+u_Phase));
    vec2 dirB = vec2(cos(2.0*M_2PI/3.0+u_Phase), sin(2.0*M_2PI/3.0+u_Phase));

    float step = u_Intensity*0.02;
    float dc = 2.0/float(u_Count);

    vec4 path = vec4(0.0, 0.0, 0.0, 1.0);
    for(int i=0; i<u_Count; ++i) {
        vec4 cR = texture2D(u_Tex0, proj0(pos + step*dirR));
        vec4 cG = texture2D(u_Tex0, proj0(pos + step*dirG));
        vec4 cB = texture2D(u_Tex0, proj0(pos + step*dirB));
        float dR = length(color-cR);
        float dG = length(color-cG);
        float dB = length(color-cB);
        if (dR>dG && dR>dB) {
            pos += step*dirR;
            path.r += dc;
        }
        else if (dG>dB) {
            pos += step*dirG;
            path.g += dc;
        }
        else {
            pos += step*dirB;
            path.b += dc;
        }
    }

    vec4 outCol = clamp(path, 0.0, 1.0);

    float intensity = getLocus(pos, outCol);
    return mix(color, outCol, intensity);
}

#include mainWithOutPos(pick)
