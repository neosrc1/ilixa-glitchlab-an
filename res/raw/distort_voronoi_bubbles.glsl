precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include smoothrandom
#include tex(1)

uniform float u_Intensity;
uniform float u_RadiusVariability;
uniform float u_Variability;
uniform float u_Perturbation;
uniform float u_Seed;
uniform float u_Distortion;
uniform float u_Radius;
uniform mat3 u_InverseModelTransform;

vec4 displace(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy; //transform(pos, center, scale);

    if (u_Perturbation > 0.0) {
        t += sineSurfaceRand2Seeded(t*(1.0+u_Perturbation*0.00), u_Seed) * 0.025*u_Perturbation;
    }
//    if (u_Perturbation > 0.0) {
//        t = perlinDisplace(t, 3, u_Perturbation*0.04);
//    }

    float ci = floor(t.x);
    float cj = floor(t.y);

    float k = 0.0;

    vec2 minDelta;
    float d2min = 1000000000.0;
    int minI = 0;
    int minJ = 0;
    vec2 minCenter;
    float minRadiusModifier;
    bool inBubble = false;
    float minRad = 0.0;

    for(int j = -2; j <= 2; ++j) {
        for(int i = -2; i <= 2; ++i) {
            vec2 center = vec2(float(i)+ci, float(j)+cj);
            vec2 delta = rand2relSeeded(center, u_Seed);
            float radiusModifier = max(0.01, 1.0 + (delta.x * u_RadiusVariability *0.01));
            float rad = u_Radius*0.01 * radiusModifier;
            float rad2 = rad*rad;
            center += vec2(0.5, 0.5) + delta*u_Variability*0.02;
            vec2 d = t - center;
            float d2 = dot(d, d);

            if (d2 < rad2) {
                bool better = true;
                if (inBubble) {
                    // distance between the 2 centers
                    vec2 dd = minCenter - center;
                    float cd2 = dot(dd, dd);
                    float cd = sqrt(cd2);

                    float minRad2 = minRad*minRad;
                    float inProj = (rad2 + cd2 - minRad2) / (2.0*cd); // position along the center's axis of the intersecting line

                    // distance of the projection of the current point on the center's axis to the current center (xx, yy)
                    float proj = dot(t-center, dd) / cd;
                    better = proj <= inProj;
                }

                if (better) {
                    inBubble = true;

                    d2min = d2;
                    minI = i;
                    minJ = j;
                    minCenter = center;
                    minDelta = delta;
                    minRadiusModifier = radiusModifier;
                    minRad = rad;
                }
            }
        }
    }

    k = sqrt(d2min);
//    k = clamp(k, 0.0, 1.0);

    vec2 newPos = pos;

    if (inBubble && u_Distortion > 0.0) {
        vec2 dd = t - minCenter;

        k /= minRad;
        float r = 1.0-k;
        float dp = u_Distortion*0.05 * (1.0-r)/(0.5+r);
        newPos += dd * dp;
//        return vec4(0.0, 0.0, 0.0, 1.0);
    }

    vec4 outColor = inBubble || u_Tex1Transform[2][2]==0.0
        ? texture2D(u_Tex0, proj0(newPos))
        : texture2D(u_Tex1, proj1(pos));

    return outColor;

}

#include mainWithOutPos(displace)
