precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Intensity;
uniform float u_Dampening;
uniform float u_Rotation;
uniform float u_RadiusVariability;
uniform float u_Variability;
uniform float u_Seed;
uniform float u_Distortion;
uniform mat3 u_InverseModelTransform;
uniform vec4 u_Color1;


vec4 disintegrate(vec2 pos, vec2 outPos) {
    float scaleWin = 30.0;
    vec2 u = scaleWin*pos;
    vec2 v = (u_ModelTransform * vec3(pos, 1.0)).xy; //transform(pos, center, scale);

    if (max(abs(v.x), abs(v.y)) < 1.0) {
        vec2 c = floor(u);

        float xOffset = 0.0;
        for(float j = -3.0; j <= 3.0; ++j) {
            if (u_Variability!=0.0) {
                vec2 rndLine = rand2relSeeded(c+vec2(j, j), u_Seed);
                xOffset = u_Variability*0.2*rndLine.y;
            }
            for(float i = -3.0; i <= 3.0; ++i) {
                vec2 tile = c + vec2(i, j);
                vec2 center = tile + vec2(0.5, 0.5);
                vec2 rnd = rand2relSeeded(center, u_Seed);

                float intensity = u_Intensity*0.02;

                vec2 delta = rnd * intensity*2.0;
                float scale = clamp(0.0, 2.5, (1.0 + intensity*(delta.x+delta.y)*0.5));
                float angle = (delta.x-delta.y)*u_Rotation*2.0;//M_PI;
                float ca = cos(angle);
                float sa = sin(angle);
                mat2 srot = mat2(ca, sa, -sa, ca)/scale;
                vec2 anterior = ((u-delta)-center) * srot + center;
                if (floor(anterior)==tile) {
                    //vec2 v = (u_InverseModelTransform * vec3(anterior, 1.0)).xy;
                    vec2 v = anterior / scaleWin;
                    return texture2D(u_Tex0, proj0(v));
                }
            }
        }
    }

    vec4 outColor = texture2D(u_Tex0, proj0(pos));

    return outColor;

}

#include mainWithOutPos(disintegrate)
