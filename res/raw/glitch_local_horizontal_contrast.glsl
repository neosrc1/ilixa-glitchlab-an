precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include locus

uniform float u_Intensity;
uniform float u_Radius;
uniform float u_Phase;

vec4 blurH(vec2 pos, float radius) {
    float pixel = 2.0 / u_Tex0Dim.y;
    int n = int(ceil(radius / pixel))+1;
    vec4 total = vec4(0.0, 0.0, 0.0, 0.0);
    vec2 p = pos - vec2(float(n)*pixel, 0.0);
    float div = 0.0;
    for(int i=-n; i<=n; ++i) {
        float d = length(vec2(float(i), 0.0)) * pixel / radius;
        if (d<=1.0) {
            float k = (d>0.5) ? (1.0-d)*(1.0-d)*2.0 : 1.0 - d*d*2.0;
            total += k*texture2D(u_Tex0, proj0(p));
            div += k;
            p.x += pixel;
        }
    }
    return total / div;
}

vec4 offset(vec2 pos, vec2 outPos) {
    float k = u_Intensity * getLocus(pos)*0.03;
    float radius = u_Radius * 0.001;
    vec4 color = texture2D(u_Tex0, proj0(pos));
    vec4 blur = blurH(pos+vec2(radius/2.0, 0.0), radius);
    return (1.0+k)*color - k*blur;
}

#include mainWithOutPos(offset)
