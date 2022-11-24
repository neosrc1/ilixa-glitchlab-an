precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Radius;
uniform float u_Dampening;

float lum(vec4 color) {
    return color.r + color.g + color.b;
}

vec4 ssmooth(vec2 pos) {
    float pixel = 2.0 / u_Tex0Dim.y;
    float radius = u_Radius * 0.01 * 0.05; // max radius is 1/40th of image size
    int n = 50;
    int m = 10;

    vec4 c = texture2D(u_Tex0, proj0(pos));

    float div = 0.0;
    float N = 1.0;
    vec4 total = c;
    vec2 delta = rand2rel(pos);
    for(int i = 0; i<n; ++i)  {
        vec2 prnd = pos + 2.0*radius * delta;
        vec4 col = texture2D(u_Tex0, proj0(prnd));
        if (length(col-c)<=u_Dampening*0.01) {
            total += col;
            ++N;
        }
        if (fmod(float(i), 4.0)==3.0) {
            delta = vec2(delta.y, -delta.x);
        }
        else {
            delta = rand2rel(delta);
        }

        if (int(N)>=m) break;
    }

    return total/N;
}
#include mainPerPixel(ssmooth)
