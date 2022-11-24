precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include random
#include locuswithcolor_nodep

uniform float u_Balance;
uniform float u_Regularity;
uniform float u_Seed;
uniform float u_Thickness;
uniform vec4 u_Color1;
uniform float u_Intensity;
uniform int u_Count;
uniform int u_Mode;

vec2 distort(vec2 pos, vec2 a, vec2 b, float intensity) {
    vec2 c = (a+b)/2.0;
    vec2 p = c + (pos-c)*pow(1.05, intensity);
    return p;
}

float round(float x, float prec) {
    return floor(x/prec+0.5)*prec;
}

float withBias(float x, float b) {
    float s = sign(b);
    float ab = abs(b);
    //return pow(x+0.5, pow(2.0, -s * min(ab, sqrt(ab)))) - 0.5;
    return pow(x+0.5, pow(2.0, -s*ab)) - 0.5;
}

vec4 pixelate(vec2 pos, vec2 outPos) {

    vec4 rect = vec4(0.0, 0.0, 0.0, 1.0);

    float intensity = u_LocusMode>=6 ? u_Intensity : u_Intensity * getLocus(pos, vec4(0.0, 0.0, 0.0, 0.0), vec4(0.0, 0.0, 0.0, 0.0));
    intensity = sign(intensity)*intensity*intensity*0.01;

    vec2 bias = (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy;
    float scale = 1.0/length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

    float ratio = round(u_Tex0Dim.x/u_Tex0Dim.y, 0.01); // preview coherence
    float pixel = 2.0/u_Tex0Dim.y;
    vec2 p = pos;

    bool border = false;
    float rndStep = 1.0;
    if (u_Mode==1 || u_Mode==8 || u_Mode==9) rndStep = 0.0;
    vec4 outCol;

    /*if (u_Mode>=9) {
    float N = 10.0;
    vec2 pa, pb;
    float k;
    for (int j=0; j<u_Count; ++j) {
        pa = vec2(floor(p.x*N)/N, p.y);
        pb = vec2(ceil(p.x*N)/N, p.y);
        k = fract(p.x*N);

        rect = vec4(-ratio, -1.0, ratio, 1.0);
        bool horSplit = true;
        vec2 splits = vec2(0.0, 0.0);// preview coherence

        float sPos = 0.0;// position in 1D split space
        float sscale = 0.5;
        float inverter = 0.0;

        for (float i=0.0; i+sPos<scale; ++i) {
            vec2 rnd = rand2relSeeded(splits, u_Seed+122.1);
            vec2 size = rect.zw-rect.xy;
            if (size.x<pixel || size.y<pixel) break;

            if (rnd.x+0.5<regularity) horSplit = size.y>size.x;
            float variability = 1.0-max(0.0, (regularity-1.0));

            if (horSplit) {
                float Y = mix(rect.y, rect.w, variability*withBias(rnd.y, bias.y)+0.5);
                if (pa.y<Y) { rect.w = Y; ++splits.y; sPos += inverter*sscale; } else { rect.y = Y; splits.y += 100.0; sPos += (1.0-inverter)*sscale; }
            }
            else {
                float X = mix(rect.x, rect.z, variability*withBias(rnd.x, bias.x)+0.5);
                if (pa.x<X) { rect.z = X; ++splits.x; sPos += inverter*sscale; } else { rect.x = X; splits.x += 100.0; sPos += (1.0-inverter)*sscale; }
            }
            horSplit = !horSplit;
            inverter = 1.0-inverter;
            sscale *= 0.5;
            bias *= 0.5;
        }
        pa = distort(pa, rect.xy, rect.zw, intensity);

        rect = vec4(-ratio, -1.0, ratio, 1.0);
        horSplit = true;
        splits = vec2(0.0, 0.0);// preview coherence

        sPos = 0.0;// position in 1D split space
        sscale = 0.5;
        inverter = 0.0;

        for (float i=0.0; i+sPos<scale; ++i) {
            vec2 rnd = rand2relSeeded(splits, u_Seed+122.1);
            vec2 size = rect.zw-rect.xy;
            if (size.x<pixel || size.y<pixel) break;

            if (rnd.x+0.5<regularity) horSplit = size.y>size.x;
            float variability = 1.0-max(0.0, (regularity-1.0));

            if (horSplit) {
                float Y = mix(rect.y, rect.w, variability*withBias(rnd.y, bias.y)+0.5);
                if (pb.y<Y) { rect.w = Y; ++splits.y; sPos += inverter*sscale; } else { rect.y = Y; splits.y += 100.0; sPos += (1.0-inverter)*sscale; }
            }
            else {
                float X = mix(rect.x, rect.z, variability*withBias(rnd.x, bias.x)+0.5);
                if (pb.x<X) { rect.z = X; ++splits.x; sPos += inverter*sscale; } else { rect.x = X; splits.x += 100.0; sPos += (1.0-inverter)*sscale; }
            }
            horSplit = !horSplit;
            inverter = 1.0-inverter;
            sscale *= 0.5;
            bias *= 0.5;
        }
        pb = distort(pb, rect.xy, rect.zw, intensity);
        p = mix(pa, pb, k);
    }
    if (u_Mode==9) {
        outCol = texture2D(u_Tex0, proj0(p));
    }
    else {
        outCol = mix(texture2D(u_Tex0, proj0(pa)), texture2D(u_Tex0, proj0(pb)), k);
    }
}
else {*/
    /*for (int j=0; j<u_Count; ++j) {
        rect = vec4(-ratio, -1.0, ratio, 1.0);

        bool horSplit = true;
        vec2 splits = vec2(0.0, 0.0);// preview coherence

        float sPos = 0.0;// position in 1D split space
        float sscale = 0.5;
        float inverter = 0.0;

        for (float i=0.0; i+sPos<scale; ++i) {
            vec2 rnd = rand2relSeeded(splits, u_Seed+122.1+float(j));
            vec2 size = rect.zw-rect.xy;
            if (size.x<pixel || size.y<pixel) break;

            if (rnd.x+0.5<regularity) horSplit = size.y>size.x;
            float variability = 1.0-max(0.0, (regularity-1.0));

            if (horSplit) {
                float Y = mix(rect.y, rect.w, variability*withBias(rnd.y, bias.y)+0.5);
                if (abs(Y-p.y)<u_Thickness*0.001) { border = true; break; }
                if (p.y<Y) { rect.w = Y; ++splits.y; sPos += inverter*sscale; } else { rect.y = Y; splits.y += 100.0; sPos += (1.0-inverter)*sscale; }
            }
            else {
                float X = mix(rect.x, rect.z, variability*withBias(rnd.x, bias.x)+0.5);
                if (abs(X-p.x)<u_Thickness*0.001) { border = true; break; }
                if (p.x<X) { rect.z = X; ++splits.x; sPos += inverter*sscale; } else { rect.x = X; splits.x += 100.0; sPos += (1.0-inverter)*sscale; }
            }
            horSplit = !horSplit;
            inverter = 1.0-inverter;
            sscale *= 0.5;
            bias *= 0.5;
        }
        if (border) break;
        p = distort(p, rect.xy, rect.zw, intensity);
        if (u_Mode>=4) p = (fract(p/vec2(2.0*ratio, 2.0)+vec2(0.5, 0.5)) - vec2(0.5,0.5))*vec2(2.0*ratio, 2.0);
    }*/


    for(int j=0; j<u_Count; ++j) {
        rect = vec4(-ratio, -1.0, ratio, 1.0);

        bool horSplit = true;
        vec2 splits = vec2(0.0, 0.0); // preview coherence

        float sPos = 0.0; // position in 1D split space
        float sscale = 0.5;
        float inverter = 0.0;
        if (rect.w<rect.y) return vec4(1.0, 0.0, 1.0, 1.0);

        float i=0.0;
        if (i+sPos<scale) {
            if (rect.w<rect.y) return i==1.0 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(1.0, 0.8*pow(0.7, i), 1.0, 1.0);
            if (rect.z<rect.x) return i==1.0 ? vec4(1.0, 1.0, 1.0, 1.0) : vec4(0.8*pow(0.7, i), 1.0, 1.0, 1.0);
            vec2 rnd = rand2relSeeded(splits, u_Seed+122.1+rndStep*float(j));
            vec2 size = rect.zw-rect.xy;
//            if (rect.w<rect.y) return vec4(0.8*pow(0.7, i), 1.0, 1.0, 1.0);
//            if (size.x<pixel || size.y<pixel) break;
            if (abs(size.x)<pixel || abs(size.y)<pixel) break;

            if (rnd.x+0.5<u_Regularity*0.02) horSplit = size.y>size.x;
            float variability = 1.0-max(0.0, (u_Regularity*0.02-1.0));

            if (horSplit) {
                float Y = mix(rect.y, rect.w, variability*withBias(rnd.y, bias.y)+0.5);
                if (abs(Y-p.y)<u_Thickness*0.001) { border = true; break; }
                if (p.y<Y) { rect.w = Y; ++splits.y; sPos += inverter*sscale; } else { rect.y = Y; splits.y += 100.0; sPos += (1.0-inverter)*sscale; }
//                if (rect.w<rect.y) return vec4(0.0, 1.0, 0.0, 1.0);
            }
            else {
                float X = mix(rect.x, rect.z, variability*withBias(rnd.x, bias.x)+0.5);
                if (abs(X-p.x)<u_Thickness*0.001) { border = true; break; }
                if (p.x<X) { rect.z = X; ++splits.x; sPos += inverter*sscale; } else { rect.x = X; splits.x += 100.0; sPos += (1.0-inverter)*sscale; }
//                if (rect.w<rect.y) return vec4(1.0, 1.0, 0.0, 1.0);
            }
            horSplit = !horSplit;
            inverter = 1.0-inverter;
            sscale *= 0.5;
            bias *= 0.5;
            ++i;
            if (rect.w<rect.y) return vec4(1.0, 1.0*pow(0.7, i), 0.0, 1.0);
        }
        if (i+sPos<scale) {
            if (rect.w<rect.y) return i==1.0 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(1.0, 0.8*pow(0.7, i), 1.0, 1.0);
            if (rect.z<rect.x) return i==1.0 ? vec4(1.0, 1.0, 1.0, 1.0) : vec4(0.8*pow(0.7, i), 1.0, 1.0, 1.0);
            vec2 rnd = rand2relSeeded(splits, u_Seed+122.1+rndStep*float(j));
            vec2 size = rect.zw-rect.xy;
//            if (rect.w<rect.y) return vec4(0.8*pow(0.7, i), 1.0, 1.0, 1.0);
//            if (size.x<pixel || size.y<pixel) break;
            if (abs(size.x)<pixel || abs(size.y)<pixel) break;

            if (rnd.x+0.5<u_Regularity*0.02) horSplit = size.y>size.x;
            float variability = 1.0-max(0.0, (u_Regularity*0.02-1.0));

            if (horSplit) {
                float Y = mix(rect.y, rect.w, variability*withBias(rnd.y, bias.y)+0.5);
                if (abs(Y-p.y)<u_Thickness*0.001) { border = true; break; }
                if (p.y<Y) { rect.w = Y; ++splits.y; sPos += inverter*sscale; } else { rect.y = Y; splits.y += 100.0; sPos += (1.0-inverter)*sscale; }
//                if (rect.w<rect.y) return vec4(0.0, 1.0, 0.0, 1.0);
            }
            else {
                float X = mix(rect.x, rect.z, variability*withBias(rnd.x, bias.x)+0.5);
                if (abs(X-p.x)<u_Thickness*0.001) { border = true; break; }
                if (p.x<X) { rect.z = X; ++splits.x; sPos += inverter*sscale; } else { rect.x = X; splits.x += 100.0; sPos += (1.0-inverter)*sscale; }
//                if (rect.w<rect.y) return vec4(1.0, 1.0, 0.0, 1.0);
            }
            horSplit = !horSplit;
            inverter = 1.0-inverter;
            sscale *= 0.5;
            bias *= 0.5;
            ++i;
            if (rect.w<rect.y) return vec4(1.0, 1.0*pow(0.7, i), 0.0, 1.0);
        }
        while (i+sPos<scale) {
            if (rect.w<rect.y) return i==1.0 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(1.0, 0.8*pow(0.7, i), 1.0, 1.0);
            if (rect.z<rect.x) return i==1.0 ? vec4(1.0, 1.0, 1.0, 1.0) : vec4(0.8*pow(0.7, i), 1.0, 1.0, 1.0);
            vec2 rnd = rand2relSeeded(splits, u_Seed+122.1+rndStep*float(j));
            vec2 size = rect.zw-rect.xy;
//            if (rect.w<rect.y) return vec4(0.8*pow(0.7, i), 1.0, 1.0, 1.0);
//            if (size.x<pixel || size.y<pixel) break;
            if (abs(size.x)<pixel || abs(size.y)<pixel) break;

            if (rnd.x+0.5<u_Regularity*0.02) horSplit = size.y>size.x;
            float variability = 1.0-max(0.0, (u_Regularity*0.02-1.0));

            if (horSplit) {
                float Y = mix(rect.y, rect.w, variability*withBias(rnd.y, bias.y)+0.5);
                if (abs(Y-p.y)<u_Thickness*0.001) { border = true; break; }
                if (p.y<Y) { rect.w = Y; ++splits.y; sPos += inverter*sscale; } else { rect.y = Y; splits.y += 100.0; sPos += (1.0-inverter)*sscale; }
//                if (rect.w<rect.y) return vec4(0.0, 1.0, 0.0, 1.0);
            }
            else {
                float X = mix(rect.x, rect.z, variability*withBias(rnd.x, bias.x)+0.5);
                if (abs(X-p.x)<u_Thickness*0.001) { border = true; break; }
                if (p.x<X) { rect.z = X; ++splits.x; sPos += inverter*sscale; } else { rect.x = X; splits.x += 100.0; sPos += (1.0-inverter)*sscale; }
//                if (rect.w<rect.y) return vec4(1.0, 1.0, 0.0, 1.0);
            }
            horSplit = !horSplit;
            inverter = 1.0-inverter;
            sscale *= 0.5;
            bias *= 0.5;
            ++i;
            if (rect.w<rect.y) return vec4(1.0, 1.0*pow(0.7, i), 0.0, 1.0);
        }
//        if (rect.w<rect.y) return vec4(0.0, 0.0, 1.0, 1.0);
        if (border) break;
        p = distort(p, rect.xy, rect.zw, intensity);
    }
//    if (rect.w<rect.y) { float ss = rect.w; rect.w = rect.y; rect.y = ss; }
//    if (rect.z<rect.x) { float ss = rect.z; rect.z = rect.x; rect.x = ss; }

    vec4 col = texture2D(u_Tex0, proj0(pos));
//    vec4 outCol = border ? vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a) : texture2D(u_Tex0, proj0(p));
//
//    if (u_LocusMode==6) {
//        vec4 col = texture2D(u_Tex0, proj0(pos));
//        float locIntensity = getLocus(pos, col, outCol);
//        return mix(col, outCol, locIntensity);
//    }
//    else {
//        return outCol;
//    }


    float dx = rect.z-rect.x;
    float dy = rect.w-rect.y;
    //float k = clamp(0.0, 1.0, dy==0.0 ? 0.0 : abs(p.y-rect.y)/abs(dy));
    float k = dy==0.0 ? 0.0 : abs(p.y-rect.y)/abs(dy);
    outCol = (dy<0.0) ? vec4(1.0, 0.0, 0.0, 1.0) : (/*dx<dy ? */mix(texture2D(u_Tex0, proj0(vec2(p.x, rect.y))), texture2D(u_Tex0, proj0(vec2(p.x, rect.w))), k)/* : mix(texture2D(u_Tex0, proj0(vec2(rect.x, p.y))), texture2D(u_Tex0, proj0(vec2(rect.z, p.y))), k)*/);
//    if (outcol2.a!=123213.0) outCol = texture2D(u_Tex0, proj0(p));


    //vec4 outCol = border ? vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a) : texture2D(u_Tex0, proj0(p));
//    if (u_Mode>=4) {
//        vec2 aa = distort(rect.xy, rect.xy, rect.zw, intensity);
//        vec2 bb = distort(rect.zw, rect.xy, rect.zw, intensity);
//        rect = vec4(aa, bb);
//    }
//    if (u_Mode==0 || u_Mode==4) {
//        float k = clamp(0.0, 1.0, dy==0.0 ? 0.0 : abs(p.y-rect.y)/abs(dy));//dy==0.0 ? 0.0 : (p.y-rect.y)/dy;
//        outCol = border ? vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a) ://texture2D(u_Tex0, proj0(p));
//        (rect.z-rect.x<rect.w-rect.y ? mix(texture2D(u_Tex0, proj0(vec2(p.x, rect.y))), texture2D(u_Tex0, proj0(vec2(p.x, rect.w))), k) : mix(texture2D(u_Tex0, proj0(vec2(rect.x, p.y))), texture2D(u_Tex0, proj0(vec2(rect.z, p.y))), k));
//    }
//    else if (u_Mode==1 || u_Mode==5) {
//        float k = rect.z-rect.x<rect.w-rect.y ? (p.y-rect.y)/(rect.w-rect.y) : (p.x-rect.x)/(rect.z-rect.x);
//        outCol = border ? vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a) :
//        (rect.z-rect.x<rect.w-rect.y ? mix(texture2D(u_Tex0, proj0(vec2(p.x, rect.y))), texture2D(u_Tex0, proj0(vec2(p.x, rect.w))), k) : mix(texture2D(u_Tex0, proj0(vec2(rect.x, p.y))), texture2D(u_Tex0, proj0(vec2(rect.z, p.y))), k));
//    }
//    else if (u_Mode==2 || u_Mode==6) {
//        float k = (p.y-rect.y)/(rect.w-rect.y);
//        outCol = border ? vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a) :
//        mix(texture2D(u_Tex0, proj0(vec2(p.x, rect.y))), texture2D(u_Tex0, proj0(vec2(p.x, rect.w))), k);
//
//    }
//    else if (u_Mode==3 || u_Mode==7) {
//        float k = (p.x-rect.x)/(rect.z-rect.x);
//        outCol = border ? vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a) :
//        mix(texture2D(u_Tex0, proj0(vec2(rect.x, p.y))), texture2D(u_Tex0, proj0(vec2(rect.z, p.y))), k);
//    }
//        else if (u_Mode==4) {
//            vec2 aa = distort(rect.xy, rect.xy, rect.zw, intensity);
//            vec2 bb = distort(rect.zw, rect.xy, rect.zw, intensity);
//            rect = vec4(aa, bb);
//            float k = (p.y-rect.y)/(rect.w-rect.y);
//            outCol = border ? vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a) :
//            (rect.z-rect.x<rect.w-rect.y ? mix(texture2D(u_Tex0, proj0(vec2(p.x, rect.y))), texture2D(u_Tex0, proj0(vec2(p.x, rect.w))), k) : mix(texture2D(u_Tex0, proj0(vec2(rect.x, p.y))), texture2D(u_Tex0, proj0(vec2(rect.z, p.y))), k));
//        }

//    }

    if (u_LocusMode>=6) {
        //vec4 col = texture2D(u_Tex0, proj0(pos));
        float locIntensity = getLocus(pos, col, outCol);
        return mix(col, outCol, locIntensity);
    }
    else {
        return outCol;
    }
}

#include mainWithOutPos(pixelate)
