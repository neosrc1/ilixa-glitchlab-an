precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_BlurVignetting;
uniform mat3 u_InverseModelTransform;


vec4 blurV(vec2 pos, float radius) {
    float pixel = 2.0 / u_Tex0Dim.y;
    int n = int(ceil(radius / pixel))+1;
    vec4 total = vec4(0.0, 0.0, 0.0, 0.0);
    vec2 p = pos - vec2(0.0, float(n)*pixel);
    float div = 0.0;
    for(int j = -n; j<=n; ++j) {
        float d = length(vec2(0.0, float(j))) * pixel / radius;
        if (d<=1.0) {
//                float k = 1.0-d;
            float k = (d>0.5) ? (1.0-d)*(1.0-d)*2.0 : 1.0 - d*d*2.0;
            total += k*texture2D(u_Tex0, proj0(p));
            div += k;
        }
        p.y += pixel;
    }
    return total / div;
}

vec4 adjust(vec2 pos, vec2 outPos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));

    if (u_BlurVignetting != 0.0) {
        vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;
        float ratio = min(1.0, length(u));
        float k = ratio*u_BlurVignetting;

        float radius = k*0.05;
        color = blurV(pos, radius);
    }


    return color;
}

#include mainWithOutPos(adjust) // should disable antialias
