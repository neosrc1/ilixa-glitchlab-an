precision highp float;
precision highp int;

#include commonvar
#include commonfun

uniform float u_Intensity;

vec4 blurHV(vec2 pos, float radius) {
    float pixel = 2.0 / u_Tex0Dim.y;
    int n = int(ceil(radius / pixel))+1;
    vec4 total = vec4(0.0, 0.0, 0.0, 0.0);
    vec2 pStart = pos - float(n)*vec2(pixel, pixel);
    vec2 p = pStart;
    float div = 0.0;
    for(int j = -n; j<=n; ++j) {
        for(int i = -n; i<=n; ++i) {
            float d = length(p-pos)/radius;
            if (d<=1.0) {
                float k = (d>0.5) ? (1.0-d)*(1.0-d)*2.0 : 1.0 - d*d*2.0;
                total += k*texture2D(u_Tex0, proj0(p));
                div += k;
            }
            p.x += pixel;
        }
        p.x = pStart.x;
        p.y += pixel;
    }
    return total / div;
}

vec4 blur(vec2 pos, vec2 outPos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));
    return blurHV(pos, u_Intensity*0.005);
}

void main() {
    vec2 pos = (u_ViewTransform * vec3(v_OutCoordinate, 1.0)).xy;
    vec4 outc = blur(pos, v_OutCoordinate);

    gl_FragColor = blend(outc, v_OutCoordinate);
}
