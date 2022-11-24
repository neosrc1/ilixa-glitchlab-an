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
uniform vec4 u_Color1;
uniform float u_Intensity;
uniform int u_Count;
uniform int u_Mode;

vec4 deffect(vec2 pos, vec2 a, vec2 b, vec2 splits, vec4 rect, float intensity) {
    vec2 rnd = rand2relSeeded(splits, u_Seed+122.1);
    if (rnd.x*2.0>u_Balance*0.01) return texture2D(u_Tex0, proj0(pos));

    float m = floor((rnd.y+0.5)*10.0);
    if (m==0.0) {
        vec4 col = texture2D(u_Tex0, proj0(floor(pos*50.0+0.5)*0.02));
        float g = floor((col.r+col.g+col.b)/3.0+0.5);
        return vec4(vec3(g), col.a);
    }
    else if (m==1.0) {
        vec4 col = texture2D(u_Tex0, proj0(pos));
        float g = floor((col.r+col.g+col.b)/3.0+0.5);
        return vec4(vec3(g), col.a);
    }
    else if (m==2.0) {
        return texture2D(u_Tex0, proj0(floor(pos*50.0+0.5)*0.02));
    }
    else if (m==3.0) {
        return texture2D(u_Tex0, proj0(vec2(pos.x, 0.0)));
    }
    else if (m==4.0) {
        return texture2D(u_Tex0, proj0(vec2(0.0, pos.y)));
    }
    else if (m==5.0) {
        vec4 col = texture2D(u_Tex0, proj0(floor(pos*100.0+0.5)*0.1*intensity));
        float g = floor((col.r+col.g+col.b)/3.0+0.5);
        return vec4(vec3(g), col.a);
    }
    else if (m==6.0) {
        vec4 r = texture2D(u_Tex0, proj0(pos+vec2(0.01, 0.0)*intensity));
        vec4 g = texture2D(u_Tex0, proj0(pos));
        vec4 b = texture2D(u_Tex0, proj0(pos-vec2(0.01, 0.0)*intensity));
        return vec4(r.r, g.g, b.b, g.a);
    }
    else {
        return texture2D(u_Tex0, proj0(floor(pos*100.0+0.5)*0.01));
    }

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
    float intensity = u_LocusMode>=6 ? u_Intensity : u_Intensity * getLocus(pos, vec4(0.0, 0.0, 0.0, 0.0), vec4(0.0, 0.0, 0.0, 0.0));
    intensity = sign(intensity)*intensity*intensity*0.01;

    vec2 bias = (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy;
    float scale = 1.0/length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

    float ratio = round(u_Tex0Dim.x/u_Tex0Dim.y, 0.01); // preview coherence
    float pixel = 2.0/u_Tex0Dim.y;
    vec2 p = pos;

    bool border = false;
    vec4 rect;

    rect = vec4(-ratio, -1.0, ratio, 1.0);

    bool horSplit = true;
    vec2 splits = vec2(0.0, 0.0); // preview coherence

    float sPos = 0.0; // position in 1D split space
    float sscale = 0.5;
    float inverter = 0.0;

    for (float i=0.0; i+sPos<scale; ++i) {
        vec2 rnd = rand2relSeeded(splits, u_Seed+122.1);
        vec2 size = rect.zw-rect.xy;
        if (size.x<pixel || size.y<pixel) break;

        if (rnd.x+0.5<u_Regularity*0.02) horSplit = size.y>size.x;
        float variability = 1.0-max(0.0, (u_Regularity*0.02-1.0));

        if (horSplit) {
            float Y = mix(rect.y, rect.w, variability*withBias(rnd.y, bias.y)+0.5);
            if (p.y<Y) { rect.w = Y; ++splits.y; sPos += inverter*sscale; } else { rect.y = Y; splits.y += 100.0; sPos += (1.0-inverter)*sscale; }
        }
        else {
            float X = mix(rect.x, rect.z, variability*withBias(rnd.x, bias.x)+0.5);
            if (p.x<X) { rect.z = X; ++splits.x; sPos += inverter*sscale; } else { rect.x = X; splits.x += 100.0; sPos += (1.0-inverter)*sscale; }
        }
        horSplit = !horSplit;
        inverter = 1.0-inverter;
        sscale *= 0.5;
        bias *= 0.5;
    }
//    if (border) break;
//    p = deffect(p, rect.xy, rect.zw, splits, rect, intensity);

    vec4 col = texture2D(u_Tex0, proj0(pos));

    vec4 outCol = border ? vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a) : deffect(p, rect.xy, rect.zw, splits, rect, intensity);

    if (u_LocusMode>=6) {
        vec4 col = texture2D(u_Tex0, proj0(pos));
        float locIntensity = getLocus(pos, col, outCol);
        return mix(col, outCol, locIntensity);
    }
    else {
        return outCol;
    }
}

#include mainWithOutPos(pixelate)
