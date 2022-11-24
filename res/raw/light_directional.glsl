precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include random
#include hsl

uniform float u_Intensity;
uniform vec4 u_Color1;
uniform float u_Variability;
uniform float u_LightAngle;
uniform float u_Blur;
uniform float u_HueOutRadius;

vec4 alphaBlend(vec4 a, vec4 b) {
    float sumA = a.a + b.a;
    if (sumA==0.0) return a;
    float k1 = a.a/sumA;
    float k2 = b.a/sumA;
    vec4 outc = k1*a + k2*b;
    outc.a = 1.0 - (1.0-a.a) * (1.0-b.a);
    return outc;
}

vec4 directional(vec2 pos, vec2 outPos) {
    vec4 inc = texture2D(u_Tex0, proj0(pos));

    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float lightDistance = 1.0 + u_Tex0Dim.x/u_Tex0Dim.y; // XXX parameterize
    float angleSize = u_LightAngle;

    vec4 baseColor = u_Color1;


    float lightX = -lightDistance;
    float lightY = 0.0;
    vec2 light = vec2(lightX, lightY);
    float d = length(light);

    float dx = t.x-lightX;
    float dy = t.y-lightY;
    vec2 delta = vec2(dx, dy);

    vec4 color;
    color.r = color.g = color.b = color.a = 0.0;
    bool inLight = false;

    float angle = getVecAngle(delta);

    int N = 1 + int(ceil(u_Variability*0.05));
    for(int i = 0; i < N; ++i) {
        float subAngleSize = angleSize/float(N);
        float subPhase = - angleSize/2.0 + subAngleSize/2.0 + subAngleSize*float(i);

        // perturbate
        vec2 var = rand2(vec2(float(N), float(i)));
        subPhase += subAngleSize * var.y*u_Variability*0.01;
        float sizeVar = var.x<0.0 ? 1.0 + var.x*u_Variability*0.005 : 1.0 + var.x*u_Variability*0.01;
        subAngleSize *= sizeVar;
        float subIntensity = u_Intensity;

        float deltaAngle = angle-subPhase;
        if (deltaAngle < -M_PI) deltaAngle += 2.0*M_PI;
        else if (deltaAngle > M_PI) deltaAngle -= 2.0*M_PI;

        if (deltaAngle > -subAngleSize/2.0 && deltaAngle <= subAngleSize/2.0) {
            inLight = true;
            vec4 newColor = baseColor;
            float kk = 1.0;
            if (u_Blur > 0.0) {
                float distFromBorder = (subAngleSize/2.0 - abs(deltaAngle)) / subAngleSize * 2.0;
                float blurDist = u_Blur*0.01;
                if (distFromBorder < blurDist) {
                    kk = distFromBorder/blurDist;
                }
            }
            if (u_HueOutRadius > 0.0) {
                vec4 hsl = RGBtoHSL(u_Color1);
                hsl[0] = hsl[0] + var.y*u_HueOutRadius;
                newColor = HSLtoRGB(hsl);
            }
            newColor.a = subIntensity*0.01 * kk;
            color = alphaBlend(color, newColor);
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
}

#include mainWithOutPos(directional)
