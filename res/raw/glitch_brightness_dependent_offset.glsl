precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include locuswithcolor

uniform float u_Intensity;
uniform float u_Phase;

vec4 offset(vec2 pos, vec2 outPos) {
    vec2 p = pos;
    float intensity = u_LocusMode>=6 ? u_Intensity : u_Intensity * getLocus(pos, vec4(0.0, 0.0, 0.0, 0.0));
//    int N = int(abs(intensity)*u_Tex0Dim.y*0.005); //int(u_Intensity*0.01 * (1.0-length(inc.xyz)));
//    float delta = 1.0/u_Tex0Dim.y * sign(intensity);
    int N = int(abs(intensity)*5.0);
    float delta = 0.001 * sign(intensity);
    vec2 disp = delta * vec2(cos(u_Phase), sin(u_Phase));
    for(int i=0; i<N; ++i) {
        vec4 inc = texture2D(u_Tex0, proj0(p));
        if (max(abs(inc.r-inc.g), abs(inc.r-inc.b))<0.01) {
            p -= disp;
        }
        if (inc.r>inc.g && inc.r>inc.b) {
            p += disp;
        }
        else if (inc.g>inc.b) {
            p += disp.yx;
        }
        else {
            p -= disp.yx;
        }

    }
    vec4 outColor = texture2D(u_Tex0, proj0(p));

    if (u_LocusMode>=6) {
        vec4 col = texture2D(u_Tex0, proj0(pos));
        float locIntensity = getLocus(pos, col, outColor);
        return mix(col, outColor, locIntensity);
    }
    else {
        return outColor;
    }
}


#include mainWithOutPos(offset)
