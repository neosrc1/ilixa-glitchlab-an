precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include locuswithcolor_nodep

uniform float u_SubAspectRatio;


vec4 pixelate(vec2 pos, vec2 outPos) {
    vec4 col = texture2D(u_Tex0, proj0(pos));
    float resolution = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    float scale = 1.0/resolution;
    float scaleY = sqrt(1.0/u_SubAspectRatio);
    float scaleX = 1.0/scaleY;
    vec2 scaleV = vec2(scaleX, scaleY)*scale;
    vec2 uu = floor(pos/scaleV + 0.5);
    vec2 du = (pos/scaleV - uu) + 0.5;
    vec2 u = uu * scaleV;
    vec2 delta = vec2(0.4, 0.0);
    vec4 cx1 = texture2D(u_Tex0, proj0(u-delta*scaleV));
    vec4 cx2 = texture2D(u_Tex0, proj0(u+delta*scaleV));
    vec4 cy1 = texture2D(u_Tex0, proj0(u-delta.yx*scaleV));
    vec4 cy2 = texture2D(u_Tex0, proj0(u+delta.yx*scaleV));


    vec4 outCol;
    if (length(cx1-cx2)>length(cy1-cy2)) {
        outCol = mix(cx1, cx2, du.x);
    }
    else {
        outCol = mix(cy1, cy2, du.y);
    }

    float intensity = getLocus(pos, col, outCol);
    return mix(col, outCol, intensity);
}

#include mainWithOutPos(pixelate)
