precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Intensity;
uniform float u_RadiusVariability;
uniform float u_Variability;
uniform float u_Balance;
uniform int u_Count;
uniform float u_Seed;

vec4 multiwhirl(vec2 pos, vec2 outPos) {
    float scale = sqrt(u_ModelTransform[0][0]*u_ModelTransform[0][0] + u_ModelTransform[0][1]*u_ModelTransform[0][1]);
    float intensity = getMaskedParameter(u_Intensity, outPos);

    for(int ii=0; ii<u_Count; ++ii) {
        vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy; //transform(pos, center, scale);

        float ci = floor(t.x);
        float cj = floor(t.y);

        float k = 0.0;

        vec2 displacement = vec2(0.0, 0.0);

        for(int j = -2; j <= 2; ++j) {
            for(int i = -2; i <= 2; ++i) {
                vec2 center = vec2(float(i)+ci, float(j)+cj);
                vec2 delta = rand2relSeeded(center, u_Seed+float(ii)*0.2);
                float radiusModifier = max(0.01, 1.0 + (delta.x * u_RadiusVariability *0.01));
                center += vec2(0.5, 0.5) + delta*u_Variability*0.01;
                vec2 d = t - center;
                k = length(d);

                float threshold = radiusModifier*0.75;
                if (k < threshold) {
                    k /= threshold;
                    k = smoothstep(0.0, 1.0, k);

                    float bal = (-u_Balance+100.0)*0.005;
                    if (bal != 0.5) {
                        if (bal==1.0 || k < bal) {
                            float ratio2 = k/bal;
                            k = 0.5 * ratio2;
                        }
                        else {
                            float ratio2 = (k-bal)/(1.0-bal);
                            k = 0.5 * (1.0-ratio2);
                        }
                    }

                    float dangle = intensity * delta.x * 0.1 * (1.0-cos(k*2.0*M_PI));
                    float ca = cos(dangle);
                    float sa = sin(dangle);
                    vec2 rotated = vec2(ca*d.x - sa*d.y, ca*d.y + sa*d.x);
                    displacement += (rotated - d) / scale;
                }
            }
        }
        pos += displacement;
    }


    return texture2D(u_Tex0, proj0(pos));

}

#include mainWithOutPos(multiwhirl)