precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include random
#include locuswithcolor_nodep

uniform sampler2D u_Palette;
uniform int u_ColorCount;
uniform int u_Count;
uniform float u_Regularity;
uniform float u_Seed;
uniform float u_Thickness;
uniform vec4 u_Color1;
uniform float u_Balance;
uniform int u_Mode;

vec4 getFromPalette(vec4 color) {
    if (u_ColorCount<=0) return color;

    float closestDist = 1e9;
    vec4 closestColor;
    for(int i=0; i<u_ColorCount; ++i) {
        float x = (0.5 + float(i))/float(u_ColorCount);
        vec4 c = texture2D(u_Palette, vec2(x, 0.0));
        float dist = length(color-c);
        if (dist < closestDist) {
            closestColor = c;
            closestDist = dist;
        }
    }

    return closestColor;
}

//vec4 sample(mat4 q, float N) {
//    vec2 pos = mix(mix(q[0], q[1], 0.5), mix(q[2], q[3], 0.5), 0.5).xy;
//    return texture2D(u_Tex0, proj0(pos));
//}

vec4 sample0(vec2 q0, vec2 q1, vec2 q2, vec2 q3, float N) {
    vec2 pos = mix(mix(q0, q1, 0.5), mix(q2, q3, 0.5), 0.5).xy;
    return texture2D(u_Tex0, proj0(pos));
}

vec4 distort(vec2 pos, vec2 a, vec2 b) {
    vec2 c = (a+b)/2.0;
    vec2 p = c + (pos-c)*pow(1.01, u_Balance);
    return texture2D(u_Tex0, proj0(p));
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

float segDist(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b-a;
    float abLen = length(ab);
    if (abLen==0.0) return length(p-a);
    vec2 abNorm = ab/abLen;
    vec2 ap = p-a;
    float abProj = dot(ap, abNorm);
    if (abProj>=0.0 && abProj<=abLen) {
        return abs(dot(ap, vec2(abNorm.y, -abNorm.x)));
    }
    else {
        return min(length(ap), length(p-b));
    }
}

//a, b, d, c in order
bool inQuad(vec2 p, vec2 E, vec2 F, vec2 A, vec2 B) {
    vec2 EA = A-E;
    float lea = length(EA);
    if (lea==0.0) {
        vec2 FB = B-F;
        float lfb = length(FB);
        if (lfb==0.0) return false;
        FB /= lfb;
        vec2 Fp = p-F;
        float lfp = length(Fp);
        if (lfp==0.0) return true;
        Fp = Fp/lfp;
        vec2 FE = normalize(E-F);
        return dot(FE, FB)<dot(Fp, FB);
    }
    else {
        EA = EA/lea;
        vec2 Ep = p-E;
        float lep = length(Ep);
        if (lep==0.0) return true;
        Ep = Ep/lep;
        vec2 EF = normalize(F-E);
        return dot(EF, EA)<dot(Ep, EA);
    }

}

// delta = -0.5 returns 0, delta = 0 returns c, delta = 0.5 returns 1
float center(float c, float delta) {
    return delta<0.0
        ? mix(0.0, c, delta*2.0+1.0)
        : mix(c, 1.0, delta*2.0);
}

//vec4 pixelate(vec2 pos, vec2 outPos) {
//    float ratio = round(u_Tex0Dim.x/u_Tex0Dim.y, 0.01); // preview coherence
//    float pixel = 2.0/u_Tex0Dim.y;
//    mat4 quad = mat4(
//        vec4(-ratio, -1.0, 0.0, 0.0), //a
//        vec4(ratio, -1.0, 0.0, 0.0), //b
//        vec4(-ratio, 1.0, 0.0, 0.0), //c
//        vec4(ratio, 1.0, 0.0, 0.0) ); //d
//
//    bool abSplit = true; // split ab and cd if true otherwise ac and bd
//    float border = 0.0;
//    vec2 splits = vec2(0.0, 0.0); // preview coherence
//    vec2 bias = (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy;
//
//    float scale = 1.0/length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
//
//    float sPos = 0.0; // position in 1D split space
//    float sscale = 0.5;
//    float inverter = 0.0;
//    float count = 0.0;
//
//    float borderThick = u_Thickness*0.0005;
//    float borderTransition = min(pixel, borderThick*0.3) *0.5;
//    float borderAA = borderThick-smoothstep(pixel*0.5, pixel, borderThick)*0.5*pixel;
//    float borderBB = borderThick + pixel*0.5;
//
//    for(float i=0.0; i+sPos<scale; ++i) {
//        vec2 rnd = rand2relSeeded(vec2(-4.0, 3.0)+splits, u_Seed+122.1);
//        vec2 size = max(abs(quad[0]-quad[3]), abs(quad[1]-quad[2])).xy;
//        if (size.x<pixel || size.y<pixel) break;
//
//        float lenAB = length(quad[0].xy-quad[1].xy) + length(quad[2].xy-quad[3].xy);
//        float lenAC = length(quad[0].xy-quad[2].xy) + length(quad[1].xy-quad[3].xy);
//
//        if (rnd.x+0.5<u_Regularity*0.02) abSplit = lenAB>lenAC;
//        float variability = 1.0-max(0.0, (u_Regularity*0.02-1.0));
////if (rnd.x==rnd.y) return vec4(1.0, 0.0, 0.0, 1.0);
//
//        float deviate = u_Balance*0.01;
//        float devEx = clamp(rnd.x+deviate, -1.0, 1.0);
//        float devFx = clamp(rnd.y+deviate, -1.0, 1.0);
//        float devEy = devEx;
//        float devFy = devFx;
//        float cEx = 0.5, cEy = 0.5, cFx = 0.5, cFy = 0.5;
//
//        if (u_Mode==1) {
//            devEx = -devEx;
//            devFy = -devFy;
//        }
//        else if (u_Mode==3) {
//            devEy = -devEy;
//        }
//        else if (u_Mode==4) {
//            cEx = 0.1;
//        }
//        else if (u_Mode==5) {
//            cEx = 0.7;
//            cEy = 0.7;
//        }
//        else if (u_Mode==6) {
//            cEx = 0.2;
//            cFx = 1.0-cEx;
//            cEy = 0.8;
//            cFy = 1.0-cEy;
//       }
//        else if (u_Mode==7) {
//            cEx = 0.2;
//            cFx = 1.0-cEx;
//            cEy = 0.2;
//            cFy = 1.0-cEy;
//        }
//
//        if (abSplit) {
//            vec4 E = mix(quad[0], quad[1], center(cEx, variability*withBias(devEx, bias.x)));
//            vec4 F = mix(quad[2], quad[3], center(cFx, variability*withBias(devFx, bias.x)));
//            float bDist = segDist(pos, E.xy, F.xy);
//            if (bDist<borderBB) { float x=bDist-borderThick; border = clamp(0.0, min(1.0, borderThick/pixel), (pixel*0.5-x)/pixel); if (border>=1.0) break; }
//            vec2 EA = quad[0].xy-E.xy;
//            vec2 EF = F.xy-E.xy;
//            if (inQuad(pos, E.xy, F.xy, quad[0].xy, quad[2].xy)) { quad = mat4(quad[0], E, quad[2], F); ++splits.y; sPos += inverter*sscale; } else { quad = mat4(E, quad[1], F, quad[3]); splits.y += 100.0; sPos += (1.0-inverter)*sscale; }
//        }
//        else {
//            vec4 E = mix(quad[0], quad[2], center(cEy, variability*withBias(devEy, bias.y)));
//            vec4 F = mix(quad[1], quad[3], center(cFy, variability*withBias(devFy, bias.y)));
//            float bDist = segDist(pos, E.xy, F.xy);
//             if (bDist<borderBB) { float x=bDist-borderThick; border = clamp(0.0, min(1.0, borderThick/pixel), (pixel*0.5-x)/pixel); if (border>=1.0) break; }
//            vec2 EA = quad[0].xy-E.xy;
//            vec2 EF = F.xy-E.xy;
//            if (inQuad(pos, E.xy, F.xy, quad[0].xy, quad[1].xy)) { quad = mat4(quad[0], quad[1], E, F); ++splits.y; sPos += inverter*sscale; } else { quad = mat4(E, F, quad[2], quad[3]); splits.y += 100.0; sPos += (1.0-inverter)*sscale; }
//        }
//
//        if (u_Mode==2) {
//            abSplit = fract(count*0.1)<0.5;
//        }
//        else {
//            abSplit = !abSplit;
//        }
//
//        inverter = 1.0-inverter;
//        sscale *= 0.5;
//        bias *= 0.5;
//        ++count;
//    }
//    vec4 col = sample(quad, 1.0);
//
////    vec4 outCol = border ? vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a) : (u_Balance==0.0 ? sample(quad, 1.0) : distort(pos, quad[0].xy, quad[2].zw));
//    vec4 outCol = mix(col, vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a), border);
//    if (u_ColorCount>1) outCol = getFromPalette(outCol);
//    vec4 bkg = texture2D(u_Tex0, proj0(pos));
//
//    float intensity = getLocus(pos, bkg, outCol);
//    return mix(bkg, outCol, intensity);
//}


vec4 pixelate(vec2 pos, vec2 outPos) {
    float ratio = round(u_Tex0Dim.x/u_Tex0Dim.y, 0.01); // preview coherence
    float pixel = 2.0/u_Tex0Dim.y;
    vec2 quad0 = vec2(-ratio, -1.0); //a
    vec2 quad1 = vec2(ratio, -1.0); //b
    vec2 quad2 = vec2(-ratio, 1.0); //c
    vec2 quad3 = vec2(ratio, 1.0); //d

    bool abSplit = true; // split ab and cd if true otherwise ac and bd
    float border = 0.0;
//    vec2 splits = vec2(0.0, 0.0); // preview coherence
    float splitsX = 0.0;
    float splitsY = 0.0;
    vec2 bias = (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy;

    float scale = 1.0/length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

    float sPos = 0.0; // position in 1D split space
    float sscale = 0.5;
    float inverter = 0.0;
    float count = 0.0;

    float borderThick = u_Thickness*0.0005;
    float borderTransition = min(pixel, borderThick*0.3) *0.5;
    float borderAA = borderThick-smoothstep(pixel*0.5, pixel, borderThick)*0.5*pixel;
    float borderBB = borderThick + pixel*0.5;

    for(float i=0.0; i+sPos<scale; ++i) {
        vec2 rnd = rand2relSeeded(vec2(-4.0, 3.0)+vec2(splitsX, splitsY), u_Seed+122.1);
        vec2 size = max(abs(quad0-quad3), abs(quad1-quad2)).xy;
        if (size.x<pixel || size.y<pixel) break;

        float lenAB = length(quad0.xy-quad1.xy) + length(quad2.xy-quad3.xy);
        float lenAC = length(quad0.xy-quad2.xy) + length(quad1.xy-quad3.xy);

        if (rnd.x+0.5<u_Regularity*0.02) abSplit = lenAB>lenAC;
        float variability = 1.0-max(0.0, (u_Regularity*0.02-1.0));
//if (rnd.x==rnd.y) return vec4(1.0, 0.0, 0.0, 1.0);

        float deviate = u_Balance*0.01;
        float devEx = clamp(rnd.x+deviate, -1.0, 1.0);
        float devFx = clamp(rnd.y+deviate, -1.0, 1.0);
        float devEy = devEx;
        float devFy = devFx;
        float cEx = 0.5, cEy = 0.5, cFx = 0.5, cFy = 0.5;

        if (u_Mode==1) {
            devEx = -devEx;
            devFy = -devFy;
        }
        else if (u_Mode==3) {
            devEy = -devEy;
        }
        else if (u_Mode==4) {
            cEx = 0.1;
        }
        else if (u_Mode==5) {
            cEx = 0.7;
            cEy = 0.7;
        }
        else if (u_Mode==6) {
            cEx = 0.2;
            cFx = 1.0-cEx;
            cEy = 0.8;
            cFy = 1.0-cEy;
       }
        else if (u_Mode==7) {
            cEx = 0.2;
            cFx = 1.0-cEx;
            cEy = 0.2;
            cFy = 1.0-cEy;
        }

        if (abSplit) {
            vec2 E = mix(quad0, quad1, center(cEx, variability*withBias(devEx, bias.x)));
            vec2 F = mix(quad2, quad3, center(cFx, variability*withBias(devFx, bias.x)));
            float bDist = segDist(pos, E.xy, F.xy);
            if (bDist<borderBB) { float x=bDist-borderThick; border = clamp(0.0, min(1.0, borderThick/pixel), (pixel*0.5-x)/pixel); if (border>=1.0) break; }
            vec2 EA = quad0.xy-E.xy;
            vec2 EF = F.xy-E.xy;
            if (inQuad(pos, E.xy, F.xy, quad0.xy, quad2.xy)) { quad1 = E; quad3 = F; ++splitsX; sPos += inverter*sscale; } else { quad0 = E; quad2 = F; splitsX += 100.0; sPos += (1.0-inverter)*sscale; }
//            if (true) { splitsY = splitsY + 1.0;  } else { splitsY = splitsY + 100.0; }
        }
        else {
            vec2 E = mix(quad0, quad2, center(cEy, variability*withBias(devEy, bias.y)));
            vec2 F = mix(quad1, quad3, center(cFy, variability*withBias(devFy, bias.y)));
            float bDist = segDist(pos, E.xy, F.xy);
            if (bDist<borderBB) { float x=bDist-borderThick; border = clamp(0.0, min(1.0, borderThick/pixel), (pixel*0.5-x)/pixel); if (border>=1.0) break; }
            vec2 EA = quad0.xy-E.xy;
            vec2 EF = F.xy-E.xy;
            if (inQuad(pos, E.xy, F.xy, quad0.xy, quad1.xy)) { quad2 = E; quad3 = F; ++splitsY; sPos += inverter*sscale; } else { quad0 = E; quad1 = F; splitsY += 100.0; sPos += (1.0-inverter)*sscale; }
//            if (true) { splitsY = splitsY + 1.0;  } else { splitsY = splitsY + 100.0; }
        }

        if (u_Mode==2) {
            abSplit = fract(count*0.1)<0.5;
        }
        else {
            abSplit = !abSplit;
        }

        inverter = 1.0-inverter;
        sscale *= 0.5;
        bias *= 0.5;
        ++count;
    }
    vec4 col = sample0(quad0, quad1, quad2, quad3, 1.0);

//    vec4 outCol = border ? vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a) : (u_Balance==0.0 ? sample(quad, 1.0) : distort(pos, quad[0].xy, quad[2].zw));
    vec4 outCol = mix(col, vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a), border);
    if (u_ColorCount>1) outCol = getFromPalette(outCol);
    vec4 bkg = texture2D(u_Tex0, proj0(pos));

    float intensity = getLocus(pos, bkg, outCol);
    return mix(bkg, outCol, intensity);
}

#include mainWithOutPos(pixelate)
