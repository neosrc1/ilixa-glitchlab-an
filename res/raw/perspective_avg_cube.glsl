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


// this version gives an interesting negative effect when dampening=-100 (cause inverses opposite edge color)
vec4 planarAvg0(vec2 pos, vec2 outPos) {
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

    if (dir.x>0.0) {
        float k3 = (-ratio-cameraPos.x)/dir.x;
        float k4 = (ratio-cameraPos.x)/dir.x;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }
    else if (dir.x<0.0) {
        float k3 = (ratio-cameraPos.x)/dir.x;
        float k4 = (-ratio-cameraPos.x)/dir.x;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    if (dir.y>0.0) {
        float k3 = (-1.0-cameraPos.y)/dir.y;
        float k4 = (1.0-cameraPos.y)/dir.y;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }
    else if (dir.y<0.0) {
        float k3 = (1.0-cameraPos.y)/dir.y;
        float k4 = (-1.0-cameraPos.y)/dir.y;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    if (dir.z>0.0) {
        float k3 = (-maxZ-cameraPos.z)/dir.z;
        float k4 = (maxZ-cameraPos.z)/dir.z;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }
    else if (dir.z<0.0) {
        float k3 = (maxZ-cameraPos.z)/dir.z;
        float k4 = (-maxZ-cameraPos.z)/dir.z;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    if (k1>k2) return backgroundColor;

    float k = k1;
    vec3 p = cameraPos + k*dir;
    vec4 color = backgroundColor;
    vec4 sumColor = vec4(0.0, 0.0, 0.0, 0.0);
    float h = 0.0;
    float dz = 0.0;
    float prevDz;
    vec4 prevColor;
    float prevH;
    bool stop;
    float sum = 0.0;
    if (u_Dampening==0.0) {
        do {
            prevColor = color;
            prevDz = dz;
            prevH = h;

            color = texture2D(u_Tex0, proj0(p.xy));
            sumColor += color;
            sum += 1.0;
            h = height(intensity, color);
            dz = p.z-h;

            p += step;
            k += dk;
            stop = stop || (dz==0.0 || (k!=k1 && sign(dz)==-sign(prevDz)));
        } while (k<=k2 /*&& !stop*/);
    }
    else {
        float weight = 1.0;
        float dw = 0.99;//pow(1.001-u_Dampening*0.01, 1.0/max(u_Tex0Dim.x, u_Tex0Dim.y));
        do {
            prevColor = color;
            prevDz = dz;
            prevH = h;

            color = texture2D(u_Tex0, proj0(p.xy));
            sumColor += weight*color;
            sum += weight;
            weight = 0.0;//*= dw;
            h = height(intensity, color);
            dz = p.z-h;

            p += step;
            k += dk;
            stop = stop || (dz==0.0 || (k!=k1 && sign(dz)==-sign(prevDz)));
        } while (k<=k2 /*&& !stop*/);
    }

    stop = stop || abs(dz)<dk;

//    if (!stop) return backgroundColor;
//    else {
        float kk = (dz==0.0) ? 1.0 : abs(prevDz)/(abs(dz)+abs(prevDz));
        float hh = mix(prevH, h, kk);
        float darken = 1.0 + u_Dampening*0.02*(hh/(intensity*0.02));
        return (sumColor/sum) * vec4(darken, darken, darken, 1.0);
//    }

}


vec4 planarAvg(vec2 pos, vec2 outPos) {
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

    if (dir.x>0.0) {
        float k3 = (-ratio-cameraPos.x)/dir.x;
        float k4 = (ratio-cameraPos.x)/dir.x;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }
    else if (dir.x<0.0) {
        float k3 = (ratio-cameraPos.x)/dir.x;
        float k4 = (-ratio-cameraPos.x)/dir.x;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    if (dir.y>0.0) {
        float k3 = (-1.0-cameraPos.y)/dir.y;
        float k4 = (1.0-cameraPos.y)/dir.y;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }
    else if (dir.y<0.0) {
        float k3 = (1.0-cameraPos.y)/dir.y;
        float k4 = (-1.0-cameraPos.y)/dir.y;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    if (dir.z>0.0) {
        float k3 = (-maxZ-cameraPos.z)/dir.z;
        float k4 = (maxZ-cameraPos.z)/dir.z;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }
    else if (dir.z<0.0) {
        float k3 = (maxZ-cameraPos.z)/dir.z;
        float k4 = (-maxZ-cameraPos.z)/dir.z;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    if (k1>k2) return backgroundColor;

    float k = k1;
    vec3 p = cameraPos + k*dir;
    vec4 color = backgroundColor;
    vec4 sumColor = vec4(0.0, 0.0, 0.0, 0.0);
    float h = 0.0;
    float dz = 0.0;
    float prevDz;
    vec4 prevColor;
    float prevH;
    bool stop;
    float sum = 0.0;
    if (u_Dampening==0.0) {
        do {
            prevColor = color;
            prevDz = dz;
            prevH = h;

            color = texture2D(u_Tex0, proj0(p.xy));
            sumColor += color;
            sum += 1.0;
            h = height(intensity, color);
            dz = p.z-h;

            p += step;
            k += dk;
            stop = stop || (dz==0.0 || (k!=k1 && sign(dz)==-sign(prevDz)));
        } while (k<=k2 /*&& !stop*/);
    }
    else {
        float weight = 1.0;
        float dw = pow(1.001-u_Dampening*0.01, 10.0/max(u_Tex0Dim.x, u_Tex0Dim.y)); // find a formula that spans a larger range
        do {
            prevColor = color;
            prevDz = dz;
            prevH = h;

            color = texture2D(u_Tex0, proj0(p.xy));
            sumColor += weight*color;
            sum += weight;
            weight *= dw;
            h = height(intensity, color);
            dz = p.z-h;

            p += step;
            k += dk;
            stop = stop || (dz==0.0 || (k!=k1 && sign(dz)==-sign(prevDz)));
        } while (k<=k2 /*&& !stop*/);
    }

    stop = stop || abs(dz)<dk;

//    if (!stop) return backgroundColor;
//    else {
        float kk = (dz==0.0) ? 1.0 : abs(prevDz)/(abs(dz)+abs(prevDz));
        float hh = mix(prevH, h, kk);
        return (sumColor/sum);
//    }

}

#include mainWithOutPos(planarAvg)
