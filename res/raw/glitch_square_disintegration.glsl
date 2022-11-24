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
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy; //transform(pos, center, scale);

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

            float intensity = u_Intensity*0.02 * smoothstep(0.0, 1.0, (center.x + xOffset)*0.1);

            vec2 delta = rnd * intensity*2.0;
            float scale = clamp(0.0, 2.5, (1.0 + intensity*(delta.x+delta.y)*0.5) * (1.0-sign(u_Dampening)*max(0.0, (center.x + xOffset)*abs(u_Dampening)*0.005)) );
            float angle = (delta.x-delta.y)*u_Rotation*2.0;//M_PI;
            float ca = cos(angle);
            float sa = sin(angle);
            mat2 srot = mat2(ca, sa, -sa, ca)/scale;
            vec2 anterior = ((u-delta)-center) * srot + center;
            if (floor(anterior)==tile) {
                vec2 v = (u_InverseModelTransform * vec3(anterior, 1.0)).xy;
                return texture2D(u_Tex0, proj0(v));
            }
        }
    }

    vec4 outColor = texture2D(u_Tex0, proj0(pos));

    return mix(outColor, vec4(u_Color1.rgb, 1.0), u_Color1.a);

}

#include mainWithOutPos(disintegrate)
