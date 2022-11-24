precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include color

uniform float u_Intensity;
uniform float u_Dampening;
uniform float u_Phase;
uniform float u_LightAngle;
uniform float u_Thickness;


float rainbowHue(float hue) {
    if (hue<0.0) return hue;
    else if (hue<150.0) { return hue/2.5; }
    else if (hue<=360.0) { float k = (hue-150.0)/210.0; return 60.0*(1.0-k) + 360.0*k; }
    else return 360.0;
}


vec4 rainbow(vec2 pos, vec2 outPos) {
    vec4 inc = texture2D(u_Tex0, proj0(pos));

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    float d = length(u);

    float blendIntensity = getMaskedParameter(u_Intensity, outPos)*0.01;

    if (u_LightAngle < M_2PI || u_Dampening!=0.0) {
        float da = 0.0;
        if (d > 0.0) {
            float ang = acos(u.x/d);
            if (u.y < 0.0) ang = M_2PI - ang;

            ang += u_Phase + M_PI/2.0 + u_LightAngle/2.0;
            ang = fmod(ang + M_2PI, M_2PI);
            if (ang > u_LightAngle) return inc;

            if (u_Dampening>0.0) {
                float fadeAngle = u_LightAngle/2.0 * u_Dampening*0.01;
                if (ang < fadeAngle) {
                    blendIntensity *= ang/fadeAngle;
                }
                else if (ang > u_LightAngle-fadeAngle) {
                    blendIntensity *= (u_LightAngle-ang)/fadeAngle;
                }
            }
        }

    }

    float thickn = 0.01*u_Thickness;

    if (d<1.0-thickn || d>1.0) return inc;

    vec4 hsl;
    hsl.r = rainbowHue(-30.0 + (1.0-d) * 360.0/thickn);
    hsl.g = 1.0;
    hsl.b = 0.5;
    hsl.a = 1.0;
    vec4 cout = HSLtoRGB(hsl);

    float centerDistance = abs(d - (1.0-thickn/2.0));
    float fadeOut = 0.3;
    float beyondFadeOut = centerDistance - thickn/2.0*(1.0-fadeOut);
    if (beyondFadeOut > 0.0) {
        blendIntensity *= (1.0 -(beyondFadeOut/(thickn/2.0*fadeOut)));
    }

    return mix(inc, cout, blendIntensity);

}

#include mainWithOutPos(rainbow)
