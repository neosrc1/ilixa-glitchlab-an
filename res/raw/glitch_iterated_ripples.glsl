precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include locuswithcolor_nodep

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Dampening;
uniform mat3 u_InverseModelTransform;
uniform vec4 u_Color;
uniform float u_Tolerance;

vec4 ripples(vec2 pos, vec2 outPos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));
    //if (length(color.rgb-u_Color.rgb)>=u_Tolerance*0.017321) return color;

    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float rippleCount = u_Count;

    float intensity = getMaskedParameter(u_Intensity, outPos);

    for(int i=0; i<6; ++i) {
        float d = length(u);

        if (d>=1.0) {
            return color;
        }
        else {
            float dampen = u_Dampening >= 0.0 ? pow(1.0-d, u_Dampening*0.02) : pow(d, -u_Dampening*0.05);
            float dilation = 1.0 + intensity*0.01 * sin(d * rippleCount * M_PI) * dampen;
            u *= dilation;
        }
    }

    if (intensity<0.0) u = -u;
    u = (u_ModelTransform * vec3(u, 1.0)).xy;
    vec4 outColor = texture2D(u_Tex0, proj0(u));

    return mix(color, outColor, getLocus(pos, color, outColor));
}

#include mainWithOutPos(ripples)