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
    float delta = 0.001;// 1.0/u_Tex0Dim.y;
    vec2 d = vec2(delta, 0.0);
//    int N = int(abs(intensity)*u_Tex0Dim.y*0.005); //int(u_Intensity*0.01 * (1.0-length(inc.xyz)));
    int N = int(abs(intensity)*5.0); //int(u_Intensity*0.01 * (1.0-length(inc.xyz)));
    for(int i=0; i<N; ++i) {
        vec4 hsl = HSLtoRGB(texture2D(u_Tex0, proj0(p)));
        float k = 1.0-2.0*abs(0.5-hsl.z);
        float angle = u_Phase + (hsl.z*2.0 + k*hsl.x/180.0)*M_PI;
        p += sign(intensity) * delta*vec2(cos(angle), sin(angle));
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
