precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include locuswithcolor_nodep

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Seed;
uniform float u_Variability;
uniform mat3 u_InverseModelTransform;

vec2 perlinDisplace(vec2 u, vec2 v, int count, float intensity) {
    float s = 1.0;
    float maxDisplacement = intensity; //pow(intensity*0.01f, 2);

    vec2 totalDisp;

    for(int i = 0; i<count; ++i) {
        vec2 disp = interpolatedRand2(v*s);
        totalDisp += maxDisplacement * (disp - vec2(0.5, 0.5))*2.0;

        maxDisplacement *= 0.5;
        s *= 2.2;
    }

    return u + totalDisp;
}

vec4 multi(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    float intensity = getMaskedParameter(u_Intensity, outPos) * (u_LocusMode>=6 ? 1.0 : getLocus(pos, vec4(0.0, 0.0, 0.0, 0.0), vec4(0.0, 0.0, 0.0, 0.0)));
    float variability = u_Variability*0.01;
    vec2 displaced = u;

    float N = variability==0.0 ? 0.0 : 2.0;
    for(float j=-N; j<=N; ++j) {
        for(float i=-N; i<=N; ++i) {
            vec2 id = floor((u+1.0)/2.0) + vec2(i, j);

            vec2 rnd = rand2relSeeded(id, u_Seed);
            vec2 rnd2 = rand2relSeeded(id+vec2(3.4, 23.3), u_Seed);
            vec2 rnd3 = rand2relSeeded(id-vec2(13.3, 7.2), u_Seed);

            vec2 center = id*2.0 + variability*vec2(rnd3.y, rnd2.y)*3.5;
            vec2 v = u-center;
            vec2 w = displaced-center;

            float radius = abs(0.6 + rnd.x*0.8 * (1.0+2.5*abs(variability)));
            if (id.x==0.0 && id.y==0.0 && radius<1.0) radius = 1.0;

            float count = floor((rnd.y+0.5)*100.0+1.0);
            float ripplesIntensity = max(0.0, rnd2.x*4.0);
            float swirlIntensity = sign(rnd2.y) * max(0.0, (abs(rnd2.y)-0.25)*8.0);
            float flowerlIntensity = sign(rnd3.x) * max(0.0, (abs(rnd3.x)-0.25)*8.0);
            float marbleIntensity = max(0.0, rnd3.y*2.0);

            float d = length(v);
            if (d<radius) {
                float k = d/radius;

                // marble
                if (marbleIntensity!=0.0) {
                    w = perlinDisplace(w, v*5.0+rnd2*3.0, 6, marbleIntensity*intensity*0.01 * smoothstep(1.0, 0.5, k));
                }

                // flower
                if (flowerlIntensity!=0.0) {
                    float angle = getVecAngle(v, d);
                    float kk = flowerlIntensity *  (1.0 - k);
                    float scaling = 1.0 + kk*intensity*0.01 * (1.0+sin((angle+M_PI) * count - M_PI/2.0));
                    w *= scaling;
                }

        //        d = length(v);
        //        k = d/radius;

                // ripples
                if (ripplesIntensity!=0.0) {
                    float dilation = 1.0 + ripplesIntensity*intensity*0.01 * sin(k * count * M_PI) * smoothstep(1.0, 0.5, k);
                    w = dilation*w;
                }

                // swirl
                if (swirlIntensity!=0.0) {
                    float dampening = 0.3;
                    float power = (rnd.x+0.6)*50.0;
                    float dangle = smoothstep(1.0, mix(0.9, -4.0, dampening), k) * swirlIntensity*intensity*0.05/pow(k, mix(0.01, 1.6, power*0.01));
                    float ca = cos(dangle);
                    float sa = sin(dangle);
                    w = vec2(ca*w.x - sa*w.y, ca*w.y + sa*w.x);
                }

                displaced = w+center;
            }
        }
    }

    vec2 coord = (u_InverseModelTransform * vec3(displaced, 1.0)).xy;
    vec4 outCol = texture2D(u_Tex0, proj0(coord));

    if (u_LocusMode>=6) {
        vec4 col = texture2D(u_Tex0, proj0(pos));
        float locIntensity = getLocus(pos, col, outCol);
        return mix(col, outCol, locIntensity);
    }
    else {
        return outCol;
    }
}


#include mainWithOutPos(multi)
