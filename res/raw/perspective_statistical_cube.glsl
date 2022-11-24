precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include tex(1)

uniform float u_Intensity;
uniform float u_Dampening;
uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;

float height(float intensity, vec4 color) {
    return intensity*0.04* ((color.r + color.g + color.b)/3.0 - 0.5);
}

vec4 planarStats(vec2 pos, vec2 outPos) {
    float intensity = getMaskedParameter(u_Intensity, outPos);
    vec4 backgroundColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;

    float maxZ = abs(intensity)*0.02;
    float ratio = (u_Tex0Dim.x/u_Tex0Dim.y);
    float dk = 2.0/u_Tex0Dim.y;
    vec3 step = dir * dk;

    float k1 = 0.0;
    float k2 = 100000000.0;

    if (dir.x!=0.0) {
        float s = sign(dir.x);
        float k3 = (-s*ratio-cameraPos.x)/dir.x;
        float k4 = (s*ratio-cameraPos.x)/dir.x;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    if (dir.y!=0.0) {
        float s = sign(dir.y);
        float k3 = (-s-cameraPos.y)/dir.y;
        float k4 = (s-cameraPos.y)/dir.y;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    if (dir.z!=0.0) {
        float s = sign(dir.z);
        float k3 = (-s*maxZ-cameraPos.z)/dir.z;
        float k4 = (s*maxZ-cameraPos.z)/dir.z;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    if (k1>k2) return backgroundColor;

    float k = k1;
    vec3 p = cameraPos + k*dir;
    vec4 color = backgroundColor;
    float h = 0.0;
    float dz = 0.0;
    float prevDz;
    vec4 prevColor;
    float prevH;
    bool stop;
    do {
        prevColor = color;
        prevDz = dz;
        prevH = h;

        color = texture2D(u_Tex0, proj0(p.xy));
        h = height(intensity, color);
        dz = p.z-h;

        p += step;
        k += dk;
        stop = dz==0.0 || (k!=k1 && sign(dz)==-sign(prevDz));
    } while (k<=k2 && !stop);

//    return vec4(k1, k2, k1>k2 ? 0.25 : 0.75, 1.0);
    stop = stop || abs(dz)<dk;

    return vec4((k2-k1), stop?1.0:0.0, (k-k1)/(k2-k1), 1.0);

}

#include mainWithOutPos(planarStats)
