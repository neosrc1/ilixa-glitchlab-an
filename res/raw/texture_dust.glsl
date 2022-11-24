precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Intensity;
uniform float u_Seed;

float voronoi_noise_at(vec2 u, int count) {
    float noise = 0.0;
    float amplitude = 0.6;

    for(int k=0; k<count; ++k) {
        vec2 v = floor(vec2(u.x+0.5, u.y+0.5));
        float closest = 10000.0;
        for(int j=-2; j<=2; ++j) {
            for(int i=-2; i<=2; ++i) {
                vec2 point = vec2(v.x+float(i), v.y+float(j));
                vec2 displace = (rand2(point) - vec2(0.5, 0.5))* 2.0;
                float distance = length(point+displace - u);
                if (distance < closest) {
                    closest = distance;
                }
            }
        }
        noise += amplitude * closest;
        amplitude *= 0.5;
        u = u*2.0 + vec2(3.34, 2.55);
    }

    return noise;
}

vec2 displace(vec2 pos) {
    vec2 t = pos;

    float ci = floor(t.x);
    float cj = floor(t.y);

    float k = 0.0;

    vec2 displacement = vec2(0.0, 0.0);
    float radiusVariability = 1.0;
    float variability = 1.0;

    for(int j = -2; j <= 2; ++j) {
        for(int i = -2; i <= 2; ++i) {
            vec2 center = vec2(float(i)+ci, float(j)+cj);
            vec2 delta = rand2relSeeded(center, u_Seed);
            float radiusModifier = max(0.3, 1.2 + (delta.x * radiusVariability));
            center += vec2(0.5, 0.5) + delta * variability;
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

    float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    float intensity = scale*0.1;
    return pos + displacement*intensity;

}

float threshold(float value) {
    //return value;
    return min(pow(min(1.1, value+0.3), 30.0), 4.0);
}


vec4 dust(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float intensity = getMaskedParameter(u_Intensity, outPos);

    vec4 color = texture2D(u_Tex0, proj0(pos));
    if (intensity != 0.0) {
//        color.rgb = color.rgb * (1.0 + perlinDisplace(pos, t, u_Count, intensity*0.02).x);
        float lumNoise = voronoi_noise_at(displace(t), 1);
        float g = threshold(lumNoise);
        color.rgb += intensity*0.01*g;//vec3(g, g, g); //color.rgb * (1.0 + intensity*0.02*lumNoise);
    }

    return color;
}

#include mainWithOutPos(dust)
