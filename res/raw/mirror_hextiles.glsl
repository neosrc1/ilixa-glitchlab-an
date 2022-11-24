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



vec4 hextiles(vec2 pos, vec2 outPos) {
//    vec2 u = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;
//    vec2 u = perspective((u_ModelTransform * vec3(pos, 1.0)).xy);
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

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

//    vec4 color = down ? vec4(1.0,0.0,0.0,1.0) : vec4(0.0,0.0,1.0,1.0);

    if (down) {
        if (dy > tileHeight - dx*SQRT3) {
            cy = (row+1.0) * tileHeight - centerHeight;
            cx = (column+1.0) * halfTileWidth;
//            color = vec4(1.0,0.0,0.0,1.0);
            down = true;
        }
        else {
            //down = true; // redundant
            cy = row * tileHeight + centerHeight;
            cx = column * halfTileWidth;
            down = false;
//            color = vec4(1.0,1.0,0.0,1.0);
        }
    }
    else {
        if (dy > dx*SQRT3) {
            // down = false; // redundant
            cy = (row+1.0) * tileHeight - centerHeight;
            cx = column * halfTileWidth;
            down = true;
//            color = vec4(0.0,0.0,1.0,1.0);
        }
        else {
            cy = row * tileHeight + centerHeight;
            cx = (column+1.0) * halfTileWidth;
//            color = vec4(0.0,1.0,1.0,1.0);
            down = false;
        }
    }
    // down now means whether we're in a down pointing triangle or not
//    color = down ? vec4(1.0,0.0,0.0,1.0) : vec4(0.0,0.0,1.0,1.0);

    float hcx, hcy;
    bool flip = down;
//    vec4 color = down ? vec4(1.0,0.0,0.0,1.0) : vec4(0.0,0.0,1.0,1.0);
    // hex center
//    int pos = int(fmod(column+5.0+3.0*row, 6.0)); //(6000000+column+5+3*row) % 6;
    int tripos = int(fmod(column + 3.0*row, 6.0)); //(6000000+column+5+3*row) % 6;
    if (tripos == 2) {
        hcx = column*halfTileWidth;
        hcy = (row+1.0)*tileHeight;
//        color = vec4(255.0, 0.0, 0.0, 1.0);
    }
    else if (tripos == 1) {
        hcx = (column+1.0)*halfTileWidth;
        hcy = (row+1.0)*tileHeight;
//        flip = down;
//        color = vec4(192.0, 192.0, 0.0, 1.0);
    }
    else if (tripos == 0) {
        if (down) {
            hcx = (column+2.0)*halfTileWidth;
            hcy = (row+1.0)*tileHeight;
        }
        else {
            hcx = (column-1.0)*halfTileWidth;
            hcy = row*tileHeight;
        }
//        color = vec4(0.0, 255.0, 0.0, 1.0);
    }
    else if (tripos == 5) {
        hcx = column*halfTileWidth;
        hcy = row*tileHeight;
//        color = vec4(0.0, 192.0, 192.0, 1.0);
    }
    else if (tripos == 4) {
        hcx = (column+1.0)*halfTileWidth;
        hcy = row*tileHeight;
//        color = vec4(0.0, 0.0, 255.0, 1.0);
    }
    else if (tripos == 3) {
        if (down) {
            hcx = (column-1.0)*halfTileWidth;
            hcy = (row+1.0)*tileHeight;
//        color = vec4(1.0, 1.0, 1.0, 1.0);
        }
        else {
            hcx = (column+2.0)*halfTileWidth;
            hcy = row*tileHeight;
//        color = vec4(0.5, 0.0, 0.5, 1.0);
        }
    }

    // recompute dx, dy , cx, cy relative to center of hex
    dx = X - hcx;
    dy = Y - hcy;

    cx -= hcx;
    cy -= hcy;


    vec2 tileSize = vec2(length(vec2(u_InverseModelTransform[0][0], u_InverseModelTransform[1][0])) * tileWidth,
                         length(vec2(u_InverseModelTransform[0][1], u_InverseModelTransform[1][1])) * tileHeight );

    float intensity = getMaskedParameter(u_Intensity, outPos);
    float s = 1.0 + intensity*0.01 * (max(2.0/tileSize.x, 2.0/tileSize.y) - 1.0);
//
//    float row = floor(u.y/tileHeight);
//    float column = floor(u.x/tileWidth);

    vec2 tileCenter = vec2(hcx, hcy);

    vec2 v = vec2(dx, dy);

    vec2 p = (u_InverseModelTransform * vec3(v*s + tileCenter, 1.0)).xy;
//    vec2 p = (u_InverseModelTransform * vec3(u, 1.0)).xy;

    float r;
    bool borderX = false;
    bool borderY = false;

    if (u_Distortion > 0.0) {
        float d = u_Distortion * 0.01;
        dx /= tileHeight;
        dy /= tileHeight;
        cx /= (tileHeight-centerHeight);
        cy /= (tileHeight-centerHeight);

        r = dx*cx + dy*cy;
        if (1.0-r < d) {
            float scale = 2.0 / sqrt(u_ModelTransform[0][0]*u_ModelTransform[0][0] + u_ModelTransform[0][1]*u_ModelTransform[0][1]);
            r = (1.0-r)/d;
            float dp = tileWidth*(1.0-r)/(0.5+r) * scale;
            p.x += cx * dp;
            p.y += cy * dp;
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

#include mainWithOutPosAndPerspectiveFit(hextiles)