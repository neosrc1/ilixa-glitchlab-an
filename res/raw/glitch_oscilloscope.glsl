precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include locuswithcolor_nodep

uniform float u_Intensity;
uniform float u_Thickness;
uniform float u_Smoothing;
uniform float u_Step;
uniform float u_Phase;
uniform int u_Count;
uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform float u_Contrast;
uniform float u_Brightness;
uniform float u_Vignetting;
uniform float u_Scanlines;

vec2 getStart(vec2 p, vec2 dir, vec2 dim) {
    float kx1 = dir.x==0.0 ? -1.0 : (-dim.x-p.x)/dir.x;
    float kx2 = dir.x==0.0 ? -1.0 : (dim.x-p.x)/dir.x;
    float ky1 = dir.y==0.0 ? -1.0 : (-dim.y-p.y)/dir.y;
    float ky2 = dir.y==0.0 ? -1.0 : (dim.y-p.y)/dir.y;
    float k = kx1;
    if (k<0.0 || kx2>=0.0 && kx2<k) k = kx2;
    if (k<0.0 || ky2>=0.0 && ky2<k) k = ky2;
    if (k<0.0 || ky1>=0.0 && ky1<k) k = ky1;
    return p+k*dir;
}

vec4 oscillo(vec2 pos, vec2 outPos) {
    float ratio = u_Tex0Dim.x / u_Tex0Dim.y;
    //vec2 dir = normalize((u_ModelTransform*vec3(1.0, 0.0, 1.0)).xy);
    vec2 dir = vec2(cos(u_Phase), sin(u_Phase));

    float pixel = 2.0/u_Tex0Dim.y;
    float step = pixel * 1.0 * u_Step;

    vec2 dim = vec2(ratio, 1.0);
    vec2 p = getStart(pos, -dir, dim);
    float k = 0.0;
    float acc = 0.0;
    float diag = length(dim);

    float radius = u_Thickness*0.0002;
    float intensity = getMaskedParameter(u_Intensity*0.01, outPos);
    float weight = step*333.33*intensity;
    //int N = int(ceil((length(p-pos)+radius)/step));
    int N = int(min((dim.x+dim.y)*2.01/pixel, ceil((length(p-pos)+radius)/step))); // min to prevent huge N coming from who knows where
    float bestL = 1e10;
    //int N = int(min(ceil((length(p-pos)+radius)/step), 2000.0));
    if (u_Vignetting==0.0 && u_Contrast==0.0 && u_Brightness==0.0 && u_Smoothing==0.0) {
        for (int i=0; i<N; ++i) {
            vec4 c = texture2D(u_Tex0, proj0(p));
            float val = (c.r+c.g+c.b);
            acc += weight*val;
            if (acc>=1.0) {
                vec2 dd = p-pos; bestL = min(bestL, dot(dd, dd)); // squared distance
                acc = 0.0;
            }
            p += step*dir;
        }
        k = smoothstep(radius, 0.0, sqrt(bestL));
    }
    else {
        for (int i=0; i<N; ++i) {
            vec4 c = texture2D(u_Tex0, proj0(p));
            float val = (c.r+c.g+c.b);
            val = (val-0.5)*(1.0 + u_Contrast*0.02) + 0.5 + u_Brightness*0.01;
            if (u_Vignetting!=0.0) {
                float vignette = mix(1.0, smoothstep(1.0, 0.0, length(p)/diag), u_Vignetting*0.01);
                val *= vignette;
            }
            acc += weight*val;
            if (acc>=1.0) {
//                vec2 dd = p-pos; bestL = min(bestL, dot(dd, dd)); // squared distance
                bestL = min(bestL, length(p-pos));
                acc = 0.0;
            }

            if (u_Smoothing>0.0) {
                acc = mix(acc, 0.5+0.5*sin(p.x*100.0), u_Smoothing*0.91 * pixel);
            }

            p += step*dir;
        }
        k = smoothstep(radius, 0.0, bestL);
    }

    vec4 bkgCol = texture2D(u_Tex0, proj0(pos));
    vec4 lineColor = vec4(mix(bkgCol.rgb, u_Color2.rgb, u_Color2.a), bkgCol.a);
    vec4 backColor = vec4(mix(bkgCol.rgb, u_Color1.rgb, u_Color1.a), bkgCol.a);
    vec4 color = mix(backColor, lineColor, clamp(0.0, 1.0, k));

    vec4 outColor = color;//mix(bkgCol, vec4(mix(bkgCol.rgb, color.rgb, color.a), bkgCol.a), 1.0);
    if (u_Scanlines!=0.0) {
        outColor.rgb *= mix(1.0, pow((1.1+sin(pos.y*400.0/ratio))*0.5, 0.4), u_Scanlines*0.01);
    }
    float locIntensity = getLocus(pos, bkgCol, outColor);
    return mix(bkgCol, outColor, locIntensity);
}

#include mainWithOutPos(oscillo)
