precision highp float;
precision highp int;

#include commonvar
#include commonfun

uniform float u_Intensity;

vec4 blur(vec2 pos, float radius) {
    int n = int(ceil(radius))+1;
    float nf = float(n);
    vec4 total = vec4(0.0, 0.0, 0.0, 0.0);
    float pixel = 1.0/u_Tex0Dim.y;
    vec2 pStart = pos - vec2(nf, nf)*pixel;
    vec2 p = pStart;
    float div = 0.0;
    float radiusP = radius*pixel;
    for(int j = -n; j<=n; ++j) {
        for(int i = -n; i<=n; ++i) {
            float d = length(p-pos)/radiusP;
            if (d<=1.0) {
                float k = (d>0.5) ? (1.0-d)*(1.0-d)*2.0 : 1.0 - d*d*2.0;
                total += k*texture2D(u_Tex0, p);
                div += k;
            }
            p.x += pixel;
        }
        p.x = pStart.x;
        p.y += pixel;
    }
    return total / div;
}

void main() {
//    vec4 outc = texture2D(u_Tex0, (v_OutCoordinate+1.0)*0.5);//blur(v_OutCoordinate, u_Intensity*0.005*u_Tex0Dim.y);
    vec4 outc = blur((v_OutCoordinate+1.0)*0.5, u_Intensity*0.005*u_Tex0Dim.y);

    gl_FragColor = blend(outc, v_OutCoordinate);
}
