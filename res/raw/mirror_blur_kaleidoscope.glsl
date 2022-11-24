precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include perspective
#include hexagon

uniform float u_Blur;
uniform float u_Offset;
uniform float u_Vignetting;

float ww(vec2 u) {
    float d = (0.5-hexDist(u))*2.0;
    return smoothstep(-u_Blur*0.01, u_Blur*0.01, d);
}

float vig(float w) {
    return mix(w, 1.0, 1.0-u_Vignetting*0.01);
}

vec4 kaleidoscope(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;

    vec4 hex = hexCoords(u);

    if (u_Blur==0.0) {
        vec2 dv = u_Offset*0.01*hex.zw;
        return texture2D(u_Tex0, proj0(hex.xy + dv));
    }
    else {
        vec4 total = vec4(0.0, 0.0, 0.0, 0.0);
        float totalWeight = 0.0;
        vec4 black = vec4(0.0, 0.0, 0.0, 1.0);

        vec2 hc = hex.xy;
        vec2 dv = u_Offset*0.01*hex.zw;
        float wCenter = ww(hc);
        total += wCenter*mix(black, texture2D(u_Tex0, proj0(hex.xy + dv)), vig(wCenter));
        totalWeight += wCenter;

        vec2 delta = vec2(1.0, 0.0);
        vec2 hexRight = hc-delta;
        dv = u_Offset*0.01*(hex.zw+delta);
        float wRight = ww(hexRight);
        totalWeight += wRight;
        total += wRight*mix(black, texture2D(u_Tex0, proj0(hexRight.xy + dv)), vig(wRight));

        delta = vec2(-1.0, 0.0);
        vec2 hexLeft = hc-delta;
        dv = u_Offset*0.01*(hex.zw+delta);
        float wLeft = ww(hexLeft);
        totalWeight += wLeft;
        total += wLeft*mix(black, texture2D(u_Tex0, proj0(hexLeft.xy + dv)), vig(wLeft));

        delta = vec2(0.5, SQRT3_2);
        vec2 hexTopRight = hc-delta;
        dv = u_Offset*0.01*(hex.zw+delta);
        float wTopRight = ww(hexTopRight);
        totalWeight += wTopRight;
        total += wTopRight*mix(black, texture2D(u_Tex0, proj0(hexTopRight.xy + dv)), vig(wTopRight));

        delta = vec2(-0.5, SQRT3_2);
        vec2 hexTopLeft = hc-delta;
        dv = u_Offset*0.01*(hex.zw+delta);
        float wTopLeft = ww(hexTopLeft);
        totalWeight += wTopLeft;
        total += wTopLeft*mix(black, texture2D(u_Tex0, proj0(hexTopLeft.xy + dv)), vig(wTopLeft));

        delta = vec2(0.5, -SQRT3_2);
        vec2 hexBottomRight = hc-delta;
        dv = u_Offset*0.01*(hex.zw+delta);
        float wBottomRight = ww(hexBottomRight);
        totalWeight += wBottomRight;
        total += wBottomRight*mix(black, texture2D(u_Tex0, proj0(hexBottomRight.xy + dv)), vig(wBottomRight));

        delta = vec2(-0.5, -SQRT3_2);
        vec2 hexBottomLeft = hc-delta;
        dv = u_Offset*0.01*(hex.zw+delta);
        float wBottomLeft = ww(hexBottomLeft);
        totalWeight += wBottomLeft;
        total += wBottomLeft*mix(black, texture2D(u_Tex0, proj0(hexBottomLeft.xy + dv)), vig(wBottomLeft));

        return total/totalWeight;
    }
}

#include mainWithOutPos(kaleidoscope)
