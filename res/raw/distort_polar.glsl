precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Blend;
uniform float u_Intensity;
uniform float u_Dampening;
uniform float u_Ratio;
uniform mat3 u_InverseModelTransform;
uniform float u_Phase;
uniform int u_Mirror;

vec4 polar(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);

    float intensity = getMaskedParameter(u_Intensity, outPos);
    float p = 1.0 + (intensity > 0.0 ? intensity*0.03 : intensity*0.0099);

    float angle = getVecAngle(u, d);

    float phase = u_Phase;

    if (u_Mirror==1) {
        angle = 2.0*(angle + phase);
        angle = fmod(angle, M_4PI);
        if (angle > M_2PI) { angle = M_4PI-angle; }
    }
    else {
        angle = angle + phase;
        angle = fmod(angle, M_2PI);
    }

    float blend = u_Blend*0.01;
    float blendedWidth = u_Tex0Dim.x * (1.0-blend*0.5);
    float fullRatio = u_Tex0Dim.x / u_Tex0Dim.y;
    float blendedRatio = blendedWidth / u_Tex0Dim.y;
    float xp = angle/M_PI - 1.0;
    float sx = blendedRatio * xp;

    float sy = 1.0 - pow(d/2.0, p) * 2.0;

    float xpp = xp/fullRatio*blendedRatio;
    float blendStart = 1.0-blend;
    if (abs(xpp) <= blendStart) {
        vec2 pos = vec2(sx, sy);
        return texture2D(u_Tex0, proj0(pos));
    }
    else {
        float k = (abs(xpp)-blendStart) / blend;
        vec2 pos1 = vec2(sx, sy);
        float sx2 = xp>=0.0 ? sx - blendedRatio*2.0 : sx + blendedRatio*2.0;
        vec2 pos2 = vec2(sx2, sy);
        return mix(texture2D(u_Tex0, proj0(pos1)), texture2D(u_Tex0, proj0(pos2)), k);
    }


}

#include mainWithOutPos(polar)
