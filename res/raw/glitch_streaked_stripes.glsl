precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include locuswithcolor_nodep

uniform vec4 u_Color1;
uniform float u_Thickness;
uniform float u_Balance;
uniform float u_Variability;
uniform float u_Shadows;
uniform float u_Seed;
uniform mat3 u_InverseModelTransform;

vec4 stripe(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    float pixel = 2.0/u_Tex0Dim.y;
    float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    float t = u_Thickness*0.0002*scale;
    float var = u_Variability*0.08;
    float index = floor(u.x+0.5);
    bool border = false;
    float light = 1.0;
    float x1, x2, i2;
    for(float i=index-6.0; i<=index+6.0; ++i) {
        vec2 rnd2 = rand2relSeeded(vec2(i, i), u_Seed);
        x1 = i + var * rnd2.x;
        float shadowSize = u_Shadows*0.04 * (1.0+u_Variability*0.01 * rnd2.y);
        i2 = i+1.0;
        x2 = i2 + var * rand2relSeeded(vec2(i2, i2), u_Seed).x;
        if (abs(u.x-x1)<t || abs(x2-u.x)<t) {
            border = true;
            break;
        }
        else if (x1<=u.x && u.x<=x2) {
            light = smoothstep(mix(-shadowSize, 0.0, u_Shadows*0.01), shadowSize, x2-u.x);
            break;
        }
    }

    vec2 rnd = rand2relSeeded(vec2(sign(u.y), i2), u_Seed);
//    float Y = abs(u_Balance*0.01)*3.0*20.0 * (1.0+0.5*var*rnd.x);
//    float dy = abs(u_Balance*0.01)*2.0*20.0 * (1.0+0.5*var*rnd.y);
    int maxIter = 30;
    float st = t;//*0.5;
    if (u_Balance<0.0) {
        float Y = 50.0/abs(u_Balance*u_Balance) *20.0 * (1.0+0.5*var*rnd.x);
        float dy = 50.0/abs(u_Balance*u_Balance) *20.0 * (1.0+0.5*var*rnd.y);
        while (abs(u.y)>Y && abs(x2-x1)>pixel && maxIter>0) {
            float k = rnd.x+0.5;
            float x12 = mix(x1, x2, k);
            if (/*st<abs(x2-x1)/2.0 && */abs(x2-x1)<st || abs(u.x-x12)<st) {
                border = true;
                x1 = x2 = x12;
                break;
            }
            else if (u.x<x12) {
                x2 = x12;
            }
            else {
                x1 = x12;
            }
            Y += dy;
            dy *= 0.5;//u_Balance*0.01;
            //st *= 0.5;
            rnd = rand2relSeeded(rnd, u_Seed);
            --maxIter;
        }
    }
    else if (u_Balance>0.0) {
        border = false;
        float Y = pow(abs(u_Balance), 1.5)*0.01 *20.0 * (1.0+0.01*var*rnd.x);
        float dy = 50.0/abs(u_Balance*u_Balance) *20.0 * (1.0+0.5*var*rnd.y);
        while (abs(u.y)<Y && abs(x2-x1)>pixel && maxIter>0) {
            float k = rnd.x+0.5;
            float x12 = mix(x1, x2, k);
            if (u.x<x12) {
                x2 = x12;
            }
            else {
                x1 = x12;
            }
            Y -= dy;
            dy *= 0.5;//u_Balance*0.01;
            //st *= 0.5;
            rnd = rand2relSeeded(rnd, u_Seed);
            --maxIter;
        }
        if (st<abs(x2-x1)/2.0 && (abs(u.x-x1)<t || abs(x2-u.x)<t)) {
            border = true;
        }
    }

    u.x = (x1+x2)/2.0;

    vec2 v = (u_InverseModelTransform * vec3(u, 1.0)).xy;
    vec4 col = texture2D(u_Tex0, proj0(v));
    vec4 outCol = border ? vec4(mix(col.rgb, u_Color1.rgb, u_Color1.a), col.a) : col;
    outCol = mix(vec4(0.0, 0.0, 0.0, 1.0), outCol, light);
    //outCol = mix(u_Color1, outCol, light);

    vec4 inCol = texture2D(u_Tex0, proj0(pos));
    float kk = getLocus(pos, inCol, outCol);
    if (kk==1.0) return outCol;
    else return mix(inCol, outCol, kk);

}

#include mainWithOutPos(stripe)
