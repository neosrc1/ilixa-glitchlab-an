precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Intensity;
uniform float u_RadiusVariability;
uniform float u_Variability;
uniform float u_Perturbation;
uniform float u_Seed;


vec4 frost(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy; //transform(pos, center, scale);

    if (u_Perturbation > 0.0) {
        t = perlinDisplace(t, 3, u_Perturbation*0.04);
    }

    float ci = floor(t.x);
    float cj = floor(t.y);

    float k = 0.0;

    vec2 displacement = vec2(0.0, 0.0);

    for(int j = -2; j <= 2; ++j) {
        for(int i = -2; i <= 2; ++i) {
            vec2 center = vec2(float(i)+ci, float(j)+cj);
            vec2 delta = rand2relSeeded(center, u_Seed);
            float radiusModifier = max(0.3, 1.2 + (delta.x * u_RadiusVariability *0.01));
            center += vec2(0.5, 0.5) + delta*u_Variability*0.01;
            vec2 d = t - center;
            k = length(d);

            float threshold = radiusModifier;
            if (k < threshold) {
                k /= threshold;
                float r = (0.5-k)*(0.5-k)*4.0;
                float dp = (1.0-r)/(0.5+r);
                displacement += dp * d;
            }
        }
    }

    float intensity = getMaskedParameter(u_Intensity, outPos);
    intensity = intensity*intensity*0.0001;
    return texture2D(u_Tex0, proj0(pos + displacement*intensity));

}


#include mainWithOutPos(frost)