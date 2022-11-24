precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include perspective

uniform float u_Distortion;
uniform float u_SubAspectRatio;
uniform float u_Pixelation;
uniform float u_Intensity;
uniform float u_LowResColorBleed;
uniform mat3 u_InverseModelTransform;

struct TriPos {
    vec2 relative;
    vec2 center;
    float ori;
} tilePos;

void triangleGridPosition(vec2 u) {
    float tileWidth = 2.0; // side of triangle
    float halfTileWidth = tileWidth/2.0; // side of triangle
    float tileHeight = tileWidth * SQRT3_2; // height of a triangle
    float centerHeight = tileWidth / (2.0*SQRT3);

    float X = u.x;
    float Y = u.y;

    float row = floor(Y/tileHeight);
    float column = floor(X/(halfTileWidth));

    float dx = X - column*halfTileWidth;
    float dy = Y - row*tileHeight;

    bool down = fmod(row+column, 2.0)==0.0; // in this rectangle the line between 2 triangles has a downward slope
    float cx, cy; // center of the triangle


    if (down) {
        if (dy > tileHeight - dx*SQRT3) {
            cy = (row+1.0) * tileHeight - centerHeight;
            cx = (column+1.0) * halfTileWidth;
            down = true;
        }
        else {
            cy = row * tileHeight + centerHeight;
            cx = column * halfTileWidth;
            down = false;
        }
    }
    else {
        if (dy > dx*SQRT3) {
            cy = (row+1.0) * tileHeight - centerHeight;
            cx = column * halfTileWidth;
            down = true;
        }
        else {
            cy = row * tileHeight + centerHeight;
            cx = (column+1.0) * halfTileWidth;
            down = false;
        }
    }

    // recompute dx, dy , cx, cy relative to center of hex
    dx = X - cx;
    dy = Y - cy;

    tilePos.relative = vec2(dx, dy);
    tilePos.center = vec2(cx, cy);
    tilePos.ori = down ? -1.0 : 1.0;
//    return val; //vec4(dx, dy, cx, cy);

}

vec4 tritiles(vec2 pos, vec2 outPos) {
//    vec2 u = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;
//    vec2 u = perspective((u_ModelTransform * vec3(pos, 1.0)).xy);
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float tileWidth = 2.0;
    float tileHeight = 2.0 * SQRT3_2;
    float centerHeight = tileWidth / (2.0*SQRT3);

    vec2 tileSize = vec2(length(vec2(u_InverseModelTransform[0][0], u_InverseModelTransform[1][0])) * tileWidth,
                         length(vec2(u_InverseModelTransform[0][1], u_InverseModelTransform[1][1])) * tileHeight );

    float intensity = getMaskedParameter(u_Intensity, outPos);
    float s = 1.0 + intensity*0.01 * (max(2.0/tileSize.x, 2.0/tileSize.y) - 1.0);
//
//    float row = floor(u.y/tileHeight);
//    float column = floor(u.x/tileWidth);

//    vec4 tilePos = triangleGridPosition(u);
    triangleGridPosition(u);

    vec2 tileCenter = tilePos.center;

    vec2 v = tilePos.relative;

    vec2 p = (u_InverseModelTransform * vec3(v*s + tileCenter, 1.0)).xy;
//    vec2 p = (u_InverseModelTransform * vec3(u, 1.0)).xy;

    vec2 r;
    bool borderX = false;
    bool borderY = false;
    float ori = tilePos.ori; //down ? -1 : 1;

    if (u_Distortion > 0.0) {
        float d = u_Distortion * 0.01;
        float dx = -v.x / centerHeight;
        float dy = -v.y / centerHeight;
        float scale = 2.0 / sqrt(u_ModelTransform[0][0]*u_ModelTransform[0][0] + u_ModelTransform[0][1]*u_ModelTransform[0][1]);
        float r0 = ori*dy;
        if (1.0-r0 < d) {
            r0 = (1.0-r0)/d;
            p.y += ori * tileWidth*(1.0-r0)/(0.5+r0) * scale;
        }

        float r1 = -dx*SQRT3_2 - ori*dy*0.5;
        if (1.0-r1 < d) {
            r1 = (1.0-r1)/d;
            float dp = tileWidth*(1.0-r1)/(0.5+r1) * scale;
            p.x += - SQRT3_2 * dp;
            p.y += -ori*0.5 * dp;
        }

        float r2 = dx*SQRT3_2 - ori*dy*0.5;
        if (1.0-r2 < d) {
            r2 = (1.0-r2)/d;
            float dp = tileWidth*(1.0-r2)/(0.5+r2) * scale;
            p.x += SQRT3_2 * dp;
            p.y += -ori*0.5 * dp;
        }
    }

    vec4 outColor = texture2D(u_Tex0, proj0(p));
    if (u_LowResColorBleed != 0.0) {
        vec2 tileCenterTexSpace = (u_InverseModelTransform * vec3(tileCenter, 1.0)).xy;
        vec4 pixelColor = texture2D(u_Tex0, proj0(tileCenterTexSpace));
        outColor = mix(outColor, pixelColor, u_LowResColorBleed*0.01);
    }

    return outColor;

}

#include mainWithOutPosAndPerspectiveFit(tritiles)