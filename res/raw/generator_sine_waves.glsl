precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include perspective

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform vec4 u_Color3;
uniform float u_Seed;
uniform float u_Intensity;
uniform float u_Variability;
uniform float u_PosterizeCount;

vec4 corners(vec2 pos, vec2 outPos) {
    pos = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;

    vec2 gridPos = (pos+vec2(1.0, 1.0))/2.0;
    vec2 gridIndex = floor(gridPos);
    vec2 uv = gridPos;

    vec4 colSum = u_Color1 + u_Color2 + u_Color3;
    float colDiv = 1.0/max(max(colSum.r, colSum.g), colSum.b);

    vec4 col = vec4(0.0, 0.0, 0.0, 1.0);
    for(float i=-1.0; i<=2.0; ++i) {
        float yIndex = gridIndex.y+i;
        vec2 rndCol = rand2relSeeded(vec2(yIndex, yIndex), 0.0)+0.5;
        vec2 rnd = rand2relSeeded(vec2(yIndex, yIndex), u_Seed);
        float freq = (0.3 + u_Variability*0.02*0.3*rnd.x)*(u_Intensity*0.1);
        if (gridPos.y<=yIndex + 0.5*sin(3.0*rnd.y + freq*gridPos.x)) {
            float k1 = rndCol.x;
            float k2 = rndCol.y;
            float k3 = fract(5.0*(rndCol.x+rndCol.y));
            return vec4(((k1*u_Color1 + k2*u_Color2 + k3*u_Color3) * colDiv).rgb, 1.0);
            break;
        }
    }

    return col;

}

#include mainWithOutPos(corners)
