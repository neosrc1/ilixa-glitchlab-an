precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform float u_PosterizeCount;
uniform float u_Hardness;
uniform float u_SubAspectRatio;
uniform float u_Roundedness;


vec4 radialGradient(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float dim = 2.0;
    float size = u_Hardness * 0.01;

    float ar = u_SubAspectRatio; //pow(1.1, u_SubAspectRatio);
    float sizeX = ar >= 1.0 ? size*dim : size*dim*ar;
    float sizeY = ar <= 1.0 ? size*dim : size*dim/ar;
    float hsizeX = sizeX/2.0;
    float hsizeY = sizeY/2.0;
    float cornerRadius = min(hsizeX, hsizeY) * (u_Roundedness*0.01); // radius of the outer border of the rectangle that is still solid c1
    float largeRadius = max(0.0, min((dim-sizeX)/2.0+cornerRadius, (dim-sizeY)/2.0+cornerRadius)); // outer radius of the rectangle beyond which is c2
    float gradientDist = largeRadius - cornerRadius;

    float left = -hsizeX + cornerRadius;
    float right = +hsizeX - cornerRadius;
    float top = -hsizeY + cornerRadius;
    float bottom = +hsizeY - cornerRadius;

    float d = 0.0;
    if (t.x < left) {
        if (t.y < top) {
            d = length(t-vec2(left, top));
        }
        else if (t.y <= bottom) {
            d = left - t.x;
        }
        else {
            d = length(t-vec2(left, bottom));
        }
    }
    else if (t.x <= right) {
        if (t.y < top) {
            d = top - t.y;
        }
        else if (t.y <= bottom) {
            d = 0.0;
        }
        else {
            d = t.y - bottom;
        }
    }
    else {
        if (t.y < top) {
            d = length(t-vec2(right, top));
        }
        else if (t.y <= bottom) {
            d = t.x - right;
        }
        else {
            d = length(t-vec2(right, bottom));
        }
    }


    float k = d <= cornerRadius ? 0.0 : (d > largeRadius ? 1.0 : (d-cornerRadius)/gradientDist);
    if (u_PosterizeCount<256.0) {
        k = min(floor(k*u_PosterizeCount) / (u_PosterizeCount-1.0), 1.0);
    }

    return mix(u_Color1, u_Color2, k);

}

#include mainWithOutPos(radialGradient)
