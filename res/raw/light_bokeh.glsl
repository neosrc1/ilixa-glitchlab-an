precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include hsl
#include hsltools

uniform vec4 u_Color1;
uniform float u_Count;
uniform float u_Intensity;
uniform float u_Variability;
uniform float u_ColorVariability;
uniform float u_Radius;
uniform float u_RadiusVariability;

vec4 alphaBlend(vec4 a, vec4 b) {
    float sumA = a.a + b.a;
    if (sumA==0.0) return a;
    float k1 = a.a/sumA;
    float k2 = b.a/sumA;
    vec4 outc = k1*a + k2*b;
    outc.a = 1.0 - (1.0-a.a) * (1.0-b.a);
    return outc;
}

vec4 circles(vec2 pos, vec2 outPos) {
    vec4 inc = texture2D(u_Tex0, proj0(pos));

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    bool inLight = false;

    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 baseColor = u_Color1;
    float intensity = getMaskedParameter(u_Intensity, pos)*0.01;//313

    vec2 v = floor(vec2(u.x+0.5, u.y+0.5));
    float closest = 10000.0;
    for(int j=-2; j<=2; ++j) {
        for(int i=-2; i<=2; ++i) {
            vec2 point = vec2(v.x+float(i), v.y+float(j));
            vec2 randomness = rand2rel(point)*2.0;
            vec2 displace = randomness*u_Variability*0.01;
            vec2 delta = point+displace - u;
            float distance = length(delta);
            float radiusModifier = randomness.x < 0.0 ? 1.0 + randomness.x * u_RadiusVariability *0.004 : 1.0 + randomness.x * u_RadiusVariability *0.02;
            float blur = (radiusModifier < 1.0 ? 1.0/radiusModifier : radiusModifier) - 1.0;

            if (u_Count < 15.0 && distance > 0.0) {
                float ang = acos(delta.x/distance);
                if (delta.y < 0.0) ang = M_2PI - ang; //ang += M_PI;

                float alpha2 = M_2PI/u_Count;
                float alpha = alpha2/2.0;
                float da = fmod(ang, alpha2);

                if (da > alpha) da = alpha2-da;

                float rounding = 1.0 + 0.25*( alpha*alpha - (alpha-da)*(alpha-da) );
                //da += phase;
                radiusModifier *= blur + (1.0-blur) * cos(alpha) / cos(alpha-da) * rounding;
            }

            float rad = u_Radius*0.01 * radiusModifier;
            float rad2 = rad*rad;
            float d2 = distance*distance;

            float kk = 0.0;
            if (d2 < rad2) {
                kk = d2/(rad2*0.97);
                kk = min(1.0, kk*kk)*0.35 + 0.65;
            }
            else if (d2<2.0*rad2) {
                kk = 1.0 - (d2-rad2)/rad2;
                kk = pow(kk, 2.0)*0.5;
            }

            if (blur > 0.0 && d2<2.0*rad2) {
                blur = min(blur, 1.0);
                float xxx = d2/(2.0*rad2);
                float kkk = (1.0 + cos(xxx*M_PI)) * 0.5;
                kk = blur*kkk + (1.0-blur)*kk;
            }

            if (kk > 0.0) {
                inLight = true;
                vec4 newColor = baseColor;
                if (u_ColorVariability > 0.0) {
                    vec4 hsl = RGBtoHSL(u_Color1);
                    hsl.x = hsl.x + randomness.y*u_ColorVariability;
                    newColor = HSLtoRGB(hsl);
                }
                newColor.a = intensity * kk;
                color = alphaBlend(color, newColor);
            }

        }
    }

    if (inLight) {
        vec4 outc = inc + color*color.a;
        outc.a = 1.0;
        return outc;
    }
    else {
        return inc;
    }



    return color;
}

#include mainWithOutPos(circles)
