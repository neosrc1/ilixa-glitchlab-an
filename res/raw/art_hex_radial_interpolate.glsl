precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include locuswithcolor

uniform int u_AxialSym;
uniform mat3 u_InverseModelTransform;
uniform float u_Phase;
uniform float u_Count;

vec4 hex(vec2 pos, vec2 outPos) {
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
    dx = X - cx;
    dy = Y - cy;

    cx -= hcx;
    cy -= hcy;

    vec2 relPos = u;//vec2(dx, dy);
    vec2 center = vec2(hcx, hcy);
    vec2 c1 = vec2(-halfTileWidth, -tileHeight) + center;
    vec2 c2 = vec2(tileWidth, 0.0) + center;
    vec2 c3 = vec2(-halfTileWidth, tileHeight) + center;


    vec2 coord = center;
    vec2 a, b;
    float d;
    float k;
    if (length(c1-relPos)<=tileWidth) {
        relPos -= c1;
        d = length(relPos);
        coord = c1;
    }
    else if (length(c2-relPos)<=tileWidth) {
        relPos -= c2;
        d = length(relPos);
        coord = c2;
    }
    else {
        relPos -= c3;
        d = length(relPos);
        coord = c3;
    }

    float ha = M_PI;
    float ang = acos(relPos.x/d);
    if (relPos.y < 0.0) ang = M_2PI - ang;

    ang += u_Phase + M_PI/2.0 + ha;
    ang = fmod(ang + M_2PI, M_2PI);
    ang = M_2PI-ang;
    float angleRange = M_2PI/u_Count;
    float index = floor(ang/M_2PI*u_Count);
    float ang1 = u_Phase-ha + angleRange*index;
    float ang2 = u_Phase-ha + angleRange*(index+1.0);
    vec2 pos1 = (u_InverseModelTransform * vec3(coord.x-d*sin(ang1), coord.y-d*cos(ang1), 1.0)).xy;
    vec4 col1 = texture2D(u_Tex0, proj0(pos1));
    vec2 pos2 = (u_InverseModelTransform * vec3(coord.x-d*sin(ang2), coord.y-d*cos(ang2), 1.0)).xy;
    vec4 col2 = texture2D(u_Tex0, proj0(pos2));

    vec4 outCol = mix(col1, col2, (ang-angleRange*index)/angleRange);
    vec2 absCoord = (u_InverseModelTransform * vec3(coord, 1.0)).xy;
//    float kk = getLocus(absCoord, outCol); // use this line for whole circles along the target edges - but caveat: doesn't handle overlaps so circles are actually "bitten" in - would need to check surrounding hexes
    float kk = getLocus(pos, outCol);
    if (kk==1.0) return outCol;
    else return mix(texture2D(u_Tex0, proj0(pos)), outCol, kk);
}

#include mainWithOutPos(hex)
