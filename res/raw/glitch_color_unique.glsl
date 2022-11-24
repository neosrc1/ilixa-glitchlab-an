precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include locuswithcolor_nodep
#include tex(1)

uniform float u_Intensity;
uniform int u_Count;
uniform float u_Phase;
uniform int u_Mode;

vec4 texAt(vec4 rect, float ratio) {
    vec2 p = vec2((rect.x+rect.z)/2.0*ratio, (rect.y+rect.w)/2.0);
    return texture2D(u_Tex0, proj0(p));
}

vec4 colorAt(vec4 rect) {
    vec2 pos = (rect.xy+rect.zw)/2.0;
    return vec4(pos, min(pos.x, pos.y), 1.0);
}
float dist(mat4 m1, mat4 m2, vec4 s) {
    int i0 = int(s[0]);
    int i1 = int(s[1]);
    int i2 = int(s[2]);
    int i3 = int(s[3]);

    return abs(m1[0].r-m2[i0].r)
            + abs(m1[0].g-m2[i0].g)
            + abs(m1[0].b-m2[i0].b)

            + abs(m1[1].r-m2[i1].r)
            + abs(m1[1].g-m2[i1].g)
            + abs(m1[1].b-m2[i1].b)

            + abs(m1[2].r-m2[i2].r)
            + abs(m1[2].g-m2[i2].g)
            + abs(m1[2].b-m2[i2].b)

            + abs(m1[3].r-m2[i3].r)
            + abs(m1[3].g-m2[i3].g)
            + abs(m1[3].b-m2[i3].b);
}

vec4 unique(vec2 pos, vec2 outPos) {
    float ratio = u_Tex0Dim.x / u_Tex0Dim.y;
    float pixel = 2.0/u_Tex0Dim.y;
    vec2 nPos = (pos / vec2(ratio, 1.0) + 1.0)/2.0;

    vec4 rect = vec4(0.0, 0.0, 1.0, 1.0);
    vec4 posRect = vec4(0.0, 0.0, 1.0, 1.0);
    int i = u_Count;
//    while (rect.z-rect.x>pixel) {
    while (--i>0) {
        vec2 center = (rect.xy+rect.zw)/2.0;
        vec2 posCenter = (posRect.xy+posRect.zw)/2.0;

        vec4 rect00 = vec4(rect.xy, center);
        vec4 rect10 = vec4(center.x, rect.y, rect.z, center.y);
        vec4 rect01 = vec4(rect.x, center.y, center.x, rect.w);
        vec4 rect11 = vec4(center, rect.zw);

        vec4 posRect00 = vec4(posRect.xy, posCenter);
        vec4 posRect10 = vec4(posCenter.x, posRect.y, posRect.z, posCenter.y);
        vec4 posRect01 = vec4(posRect.x, posCenter.y, posCenter.x, posRect.w);
        vec4 posRect11 = vec4(posCenter, posRect.zw);

        mat4 rects = mat4(rect00, rect01, rect10, rect11);
        mat4 cr = mat4(colorAt(rect00), colorAt(rect01), colorAt(rect10), colorAt(rect11));
        mat4 ct = mat4(texAt(posRect00, ratio), texAt(posRect01, ratio), texAt(posRect10, ratio), texAt(posRect11, ratio));

        vec4 shuffle = vec4(0.0, 1.0, 2.0, 3.0);
        float bestDist = dist(ct, cr, shuffle);
        vec4 bestShuffle = shuffle;
        float d;

        shuffle = vec4(0.0, 1.0, 3.0, 2.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(0.0, 3.0, 1.0, 2.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(0.0, 3.0, 2.0, 1.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(0.0, 2.0, 1.0, 3.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(0.0, 2.0, 3.0, 1.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }

        shuffle = vec4(1.0, 0.0, 2.0, 3.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(1.0, 0.0, 3.0, 2.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(1.0, 2.0, 0.0, 3.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(1.0, 2.0, 3.0, 0.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(1.0, 3.0, 0.0, 2.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(1.0, 3.0, 2.0, 0.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }

        shuffle = vec4(2.0, 0.0, 1.0, 3.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(2.0, 0.0, 3.0, 1.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(2.0, 1.0, 0.0, 3.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(2.0, 1.0, 3.0, 0.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(2.0, 3.0, 0.0, 1.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(2.0, 3.0, 1.0, 0.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }

        shuffle = vec4(3.0, 0.0, 1.0, 2.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(3.0, 0.0, 2.0, 1.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(3.0, 1.0, 0.0, 2.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(3.0, 1.0, 2.0, 0.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(3.0, 2.0, 0.0, 1.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }
        shuffle = vec4(3.0, 2.0, 1.0, 0.0); d = dist(ct, cr, shuffle); if (d<bestDist) { bestDist = d; bestShuffle=shuffle; }

//        bestShuffle =vec4(0.0, 3.0, 2.0, 1.0);
        if (nPos.x<posCenter.x) {
            if (nPos.y<posCenter.y) {
                rect = rects[int(bestShuffle[0])];
                posRect = posRect00;
            }
            else {
                rect = rects[int(bestShuffle[1])];
                posRect = posRect01;
            }
        }
        else {
            if (nPos.y<posCenter.y) {
                rect = rects[int(bestShuffle[2])];
                posRect = posRect10;
            }
            else {
                rect = rects[int(bestShuffle[3])];
                posRect = posRect11;
            }
        }
    }
    vec4 outColor = colorAt(rect);

//    vec4 outColor = colorAt(nPos);
    vec4 color = texture2D(u_Tex0, proj0(pos));
    float intensity = getLocus(pos, color, outColor);
    return mix(color, outColor, intensity);
}

#include mainWithOutPos(unique)
