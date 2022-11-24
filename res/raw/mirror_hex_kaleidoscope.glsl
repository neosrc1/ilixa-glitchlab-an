precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include perspective

uniform int u_AxialSym;
uniform float u_Offset;

vec4 kaleidoscope(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;

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
    dx = X - cx;
    dy = Y - cy;

    cx -= hcx;
    cy -= hcy;


    cx /= (tileHeight-centerHeight);
    cy /= (tileHeight-centerHeight);


    // rotation using (cy, cx) as (cos(a), sin(a))
    float px = ((flip && u_AxialSym==1)?-1.0:1.0) * (cy*dx - cx*dy);
    float py = cx*dx + cy*dy;
//    float px = cy*dx - cx*dy;
//    float py = cx*dx + cy*dy;
//    if (phase != 0.0) {
//        float cosPhase = cos(u_Phase);
//        float sinPhase = sin(u_Phase);
//        float oldPx =  px;
//        px = cosPhase*px - sinPhase*py;
//        py = sinPhase*oldPx + cosPhase*py;
//    }

    vec2 coord = vec2(px, py) + u_Offset*u_Offset*0.0001*u;
//    vec2 coord = vec2(dx, dy);
    return texture2D(u_Tex0, proj0(coord));
//    return mix(texture2D(u_Tex0, proj0(coord)), color, 0.3);

}

#include mainWithOutPos(kaleidoscope)
