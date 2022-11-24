precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include hsl

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform int u_Count;
uniform float u_PosterizeCount;
uniform float u_Variability;
uniform float u_ColorVariability;
uniform float u_Radius;
uniform float u_RadiusVariability;

vec4 getColor(vec4 color, vec2 delta) {
    float deltaHue = delta.x * u_ColorVariability*0.02;
    vec4 hsl = RGBtoHSL(color);
    hsl.x += deltaHue*180.0;
    hsl.z *= (1.0 + 0.3*delta.y);
    return HSLtoRGB(hsl);
}

vec4 circles(vec2 pos, vec2 outPos) {

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec2 v = floor(vec2(u.x+0.5, u.y+0.5));
    float closest = 10000.0;
    int j = -2;
    int jEnd = 2;
    bool inCircle = false;
    bool shadowed = false;
    vec2 shadowingRnd;
    vec2 shadowingDisplacedPoint = vec2(0.0, 9999999.0*99999999999.0);
    vec2 shadowingPoint;
    float minDistance = 100000.0;
    while (j<=jEnd) {
        for(int i=-2; i<=2; ++i) {
            vec2 point = vec2(v.x+float(i), v.y+float(j));
            vec2 rnd = rand2rel(point);
            vec2 displace = rnd * u_Variability*0.02;
            vec2 displacedPoint = point+displace;
            if (shadowingDisplacedPoint.y > displacedPoint.y) {
                float distance = length(displacedPoint - u);
                float radius = u_Radius*0.01 * (1.0 + displace.x*u_RadiusVariability*0.01);

                bool inRadius = distance < radius;
                if (abs(displacedPoint.x - u.x) < radius && (inRadius || displacedPoint.y > u.y)) {
                    minDistance = min(minDistance, distance);
                    shadowingPoint = point;
                    shadowingDisplacedPoint = displacedPoint;
                    shadowingRnd = rnd;
                    shadowed = true;
                    inCircle = inRadius;
                }
            }
        }
        if (!shadowed && jEnd<100) ++jEnd;
        ++j;
    }

    if (shadowed) {
        vec4 baseColor = getColor(u_Color1, shadowingRnd);
        return inCircle ? baseColor : vec4(mix((baseColor.rgb+0.2)*1.15, u_Color2.rgb, min(1.0, 0.5*minDistance)), baseColor.a);
    }

    return u_Color2;

}

#include mainWithOutPos(circles)
