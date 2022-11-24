precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include perspective
#include hsl
#include locuswithcolor

uniform float u_Distortion;
uniform float u_SubAspectRatio;
uniform float u_Pixelation;
uniform float u_Intensity;
uniform float u_LowResColorBleed;
uniform mat3 u_InverseModelTransform;
uniform float u_Count;

vec4 recttiles(vec2 pos, vec2 outPos) {
    float locusStrength = u_LocusMode>=6 ? 1.0 : getLocus(pos, vec4(0.0, 0.0, 0.0, 0.0));

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float tileWidth = 2.0;
    float tileHeight = 2.0 * u_SubAspectRatio;

    vec2 tileSize = vec2(length(vec2(u_InverseModelTransform[0][0], u_InverseModelTransform[1][0])) * tileWidth,
                         length(vec2(u_InverseModelTransform[0][1], u_InverseModelTransform[1][1])) * tileHeight );

    float intensity = getMaskedParameter(u_Intensity, outPos) * 0.1;
    float s = 1.0 + intensity*0.01 * locusStrength * (max(2.0/tileSize.x, 2.0/tileSize.y) - 1.0);

    vec2 tileCenter;
    vec2 p;

    for(int i=0; i<int(u_Count); ++i) {
        float row = floor(u.y/tileHeight);
        float column = floor(u.x/tileWidth);

        tileCenter = vec2((column+0.5) * tileWidth, (row+0.5) * tileHeight);

        vec2 v = u - tileCenter;

        p = (u_InverseModelTransform * vec3(v*s + tileCenter, 1.0)).xy;

        vec2 r;
        bool borderX = false;
        bool borderY = false;
        if (u_Distortion > 0.0) {
            float d = u_Distortion * 0.01;
            r = v / vec2(tileWidth, tileHeight) + vec2(0.5, 0.5);

            if (r.x < d/2.0) {
                r.x = 2.0*r.x/d;
                borderX = true;
                p.x -= tileSize.x*(1.0-r.x)/(0.5+r.x);
            }
            else if (r.x > 1.0-d/2.0) {
                r.x = 2.0*(1.0-r.x)/d;
                borderX = true;
                p.x += tileSize.x*(1.0-r.x)/(0.5+r.x);
            }

            if (r.y < d/2.0) {
                r.y = 2.0*r.y/d;
                borderY = true;
                p.y -= tileSize.y*(1.0-r.y)/(0.5+r.y);
            }
            else if (r.y > 1.0-d/2.0) {
                r.y = 2.0*(1.0-r.y)/d;
                borderY = true;
                p.y += tileSize.y*(1.0-r.y)/(0.5+r.y);
            }
        }
        u = (u_ModelTransform * vec3(p, 1.0)).xy;//p;
    }

    vec4 outColor = texture2D(u_Tex0, proj0(p));
    if (u_LowResColorBleed != 0.0) {
        vec2 tileCenterTexSpace = (u_InverseModelTransform * vec3(tileCenter, 1.0)).xy;
        vec4 pixelColor = texture2D(u_Tex0, proj0(tileCenterTexSpace));
        outColor = mix(outColor, pixelColor, u_LowResColorBleed*0.01);
    }

    if (u_LocusMode>=6) {
        vec4 col = texture2D(u_Tex0, proj0(pos));
        float locIntensity = getLocus(pos, col, outColor);
        return mix(col, outColor, locIntensity);
    }
    else {
        return outColor;
    }

}

#include mainWithOutPosAndPerspectiveFit(recttiles)