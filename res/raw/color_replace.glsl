precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform float u_Tolerance;
uniform float u_Dampening;

float colorDistance(vec4 c1, vec4 c2) {
    return length(c1.rgb-c2.rgb);
}

vec4 replace(vec2 pos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));

    float tolerance = getMaskedParameter(u_Tolerance, pos) * 0.01;
    float dampening = u_Dampening * 0.01;
    float replaceMaxDistance = tolerance*1.7320508075688772;
    float fullReplaceMaxDistance = replaceMaxDistance*(1.0-dampening);

    float dist = colorDistance(color, u_Color1);
    if (dist >= replaceMaxDistance) {
        return color;
    }

    if (dist <= fullReplaceMaxDistance) {
        return u_Color2;
    }

    float k = (dist-fullReplaceMaxDistance) / (replaceMaxDistance-fullReplaceMaxDistance);

    return mix(u_Color2, color, k);
}

#include mainPerPixel(replace) // should disable antialias
