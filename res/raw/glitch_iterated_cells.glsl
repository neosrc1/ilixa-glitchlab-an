precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

#include hsl
#include locuswithcolor

uniform float u_Intensity;
uniform float u_RadiusVariability;
uniform float u_Variability;
uniform float u_Seed;
uniform float u_Distortion;
uniform mat3 u_InverseModelTransform;
uniform int u_Count;


vec4 displace(vec2 pos, vec2 outPos) {
    vec2 origPos = pos;

    float locusStrength = u_LocusMode>=6 ? 1.0 : getLocus(pos, vec4(0.0, 0.0, 0.0, 0.0));

    float intensity = getMaskedParameter(u_Intensity, outPos) * locusStrength;
    for(int ii=0; ii<u_Count; ++ii) {
        vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy; //transform(pos, center, scale);

        float ci = floor(t.x);
        float cj = floor(t.y);

        float k = 0.0;

        vec2 minDelta;
        float d2min = 1000000000.0;
        int minI = 0;
        int minJ = 0;
        vec2 minCenter;
        float minRadiusModifier;

        for(int j = -2; j <= 2; ++j) {
            for(int i = -2; i <= 2; ++i) {
                vec2 center = vec2(float(i)+ci, float(j)+cj);
                vec2 delta = rand2relSeeded(center, u_Seed);
                float radiusModifier = max(0.01, 1.0 + (delta.x * u_RadiusVariability *0.01));
                center += vec2(0.5, 0.5) + delta*u_Variability*0.02;
                vec2 d = t - center;
                float d2 = abs(d.x)+abs(d.y);//dot(d, d);

                if (d2/radiusModifier < d2min) {
                    d2min = d2;
                    minI = i;
                    minJ = j;
                    minCenter = center;
                    minDelta = delta;
                    minRadiusModifier = radiusModifier;
                }
            }
        }

        k = sqrt(d2min);
        k = clamp(k, 0.0, 1.0);

        vec2 delta = minDelta * intensity*0.02;
        vec2 newPos = pos + delta;

        if (d2min > 0.0 && u_Distortion > 0.0) {
                vec2 dd = t - minCenter;
                float radius = 100.0; //???????????
                float threshold = radius*0.01 * minRadiusModifier;
                if (k < threshold) {
                    k /= threshold;
                    float r = 1.0-k;
                    float dp = u_Distortion*0.02 * (1.0-r)/(0.5+r);
                    newPos += dd * dp;
                }
        }
        pos = newPos;
    }

    vec4 outColor = texture2D(u_Tex0, proj0(pos));

    if (u_LocusMode>=6) {
        vec4 col = texture2D(u_Tex0, proj0(origPos));
        float locIntensity = getLocus(origPos, col, outColor);
        return mix(col, outColor, locIntensity);
    }
    else {
        return outColor;
    }

}

#include mainWithOutPos(displace)
