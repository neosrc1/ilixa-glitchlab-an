precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Intensity;
uniform float u_Seed;
uniform float u_Regularity;
uniform float u_Dispersion;
uniform float u_Vignetting;
uniform int u_Count;
uniform vec4 u_Color1;

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

vec2 getDisplacement(vec2 pos) {
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

    float scale = 10.0;//length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    float intensity = scale*0.3 * (1.0-u_Regularity*0.01);
    return displacement*intensity;

}

float threshold(float value) {
    //return value;
    return min(pow(min(1.2, value+0.35), 10.0), 4.0);
}


vec4 dust(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float intensity = getMaskedParameter(u_Intensity, outPos);

    vec4 color = texture2D(u_Tex0, proj0(pos));

    float falloff = 1.0;
    if (u_Vignetting != 0.0) {
        float diag = max(1.0, u_Tex0Dim.x/u_Tex0Dim.y);
        float len = length(outPos);
        float radius = (1.5-u_Vignetting*0.01) * diag;
        falloff = max(0.0, (1.0 - u_Vignetting*0.02*smoothstep(0.0, radius, len)));
    }

    if (intensity != 0.0) {
        vec3 light;
        if (u_Dispersion == 0.0) {
            int n = u_Count;
            vec2 displacement = getDisplacement(t);
            float g = threshold(voronoi_noise_at(t + displacement, n));
            light = u_Color1.rgb * vec3(g, g, g);
        }
        else {
            float ab = (u_Dispersion*0.01) * 10.0/(101.0-u_Regularity);
            int n = u_Count;
            vec2 displacement = getDisplacement(t);
            float r = threshold(voronoi_noise_at(t + displacement*(1.0-ab), n));
            float y = threshold(voronoi_noise_at(t + displacement*(1.0-0.5*ab), n));
            float g = threshold(voronoi_noise_at(t + displacement, n));
            float c = threshold(voronoi_noise_at(t + displacement*(1.0+0.5*ab), n));
            float b = threshold(voronoi_noise_at(t + displacement*(1.0+1.5*ab), n));
            light = u_Color1.rgb * vec3(r*0.66+0.33*y, 0.4*y+0.2*g+0.4*c, 0.15*c + 0.85*b);
        }

        color.rgb += intensity*0.05 * light * falloff;
    }

    return color;
}

#include mainWithOutPos(dust)
