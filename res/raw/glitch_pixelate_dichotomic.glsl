precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include random
#include locuswithcolor_nodep

uniform sampler2D u_Palette;
uniform float u_Balance;
uniform int u_ColorCount;
uniform int u_Count;
uniform float u_Regularity;
uniform float u_Seed;
uniform float u_Thickness;
uniform vec4 u_Color1;
uniform float u_Intensity;

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

vec4 sampleRect(vec2 a, vec2 b, float N) {
    vec2 delta = (b-a)/N;
    vec2 p = a + delta/2.0;
    delta = vec2(max(delta.x, 0.0000001), max(delta.y, 0.0000001));
    vec4 total;
    for(; p.y<b.y; p.y += delta.y) {
        for(; p.x<b.x; p.x += delta.x) {
            total += texture2D(u_Tex0, proj0(p));
        }
    }
    return texture2D(u_Tex0, proj0((a+b)/2.0));//total/(N*N);
}

vec4 distort(vec2 pos, vec2 a, vec2 b) {
    vec2 c = (a+b)/2.0;
    vec2 p = c + (pos-c)*pow(1.01, u_Intensity);
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

vec4 pixelate(vec2 pos, vec2 outPos) {
    float ratio = round(u_Tex0Dim.x/u_Tex0Dim.y, 0.01); // preview coherence
    float pixel = 2.0/u_Tex0Dim.y;
    vec4 rect = vec4(-ratio, -1.0, ratio, 1.0);

    bool horSplit = true;
    bool border = false;
    vec2 splits = vec2(0.0, 0.0); // preview coherence
    vec2 bias = (u_ModelTransform*vec3(0.0, 0.0, 1.0)).xy;

    float scale = 1.0/length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

    float sPos = 0.0; // position in 1D split space
    float sscale = 0.5;
    float inverter = 0.0;

    for(float i=0.0; i+sPos<scale; ++i) {
        vec2 rnd = rand2relSeeded(splits, u_Seed+122.1);
        vec2 size = rect.zw-rect.xy;
        if (size.x<pixel || size.y<pixel) break;

        if (rnd.x+0.5<u_Regularity*0.02) horSplit = size.y>size.x;
        float variability = 1.0-max(0.0, (u_Regularity*0.02-1.0));

        if (horSplit) {
            float Y = mix(rect.y, rect.w, variability*withBias(rnd.y, bias.y)+0.5);
            if (abs(Y-pos.y)<u_Thickness*0.001) { border = true; break; }
            if (pos.y<Y) { rect.w = Y; ++splits.y; sPos += inverter*sscale; } else { rect.y = Y; splits.y += 100.0; sPos += (1.0-inverter)*sscale; }
        }
        else {
            float X = mix(rect.x, rect.z, variability*withBias(rnd.x, bias.x)+0.5);
            if (abs(X-pos.x)<u_Thickness*0.001) { border = true; break; }
            if (pos.x<X) { rect.z = X; ++splits.x; sPos += inverter*sscale; } else { rect.x = X; splits.x += 100.0; sPos += (1.0-inverter)*sscale; }
        }
        horSplit = !horSplit;
        inverter = 1.0-inverter;
        sscale *= 0.5;
        bias *= 0.5;
    }
    vec4 col = texture2D(u_Tex0, proj0(pos));

    vec4 outCol = border ? vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a) : (u_Intensity==0.0 ? sampleRect(rect.xy, rect.zw, 1.0) : distort(pos, rect.xy, rect.zw));
    if (u_ColorCount>1 && !border) outCol = getFromPalette(outCol);

    float intensity = getLocus(pos, col, outCol);
    return mix(col, outCol, intensity);
}

#include mainWithOutPos(pixelate)
