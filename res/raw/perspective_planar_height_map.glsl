precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include tex(1)
#include tex(2)

uniform float u_Intensity;
uniform int u_Count;
uniform float u_ColorScheme;
uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;


float height(float intensity, vec4 color) {
    float g = (color.r + color.g + color.b)/3.0;
    float count = float(u_Count-1);
    float gQuant = floor(g*count+0.5)/count;
    return intensity*0.04* (gQuant - 0.5);
}

vec4 getBackground(vec2 pos) {
    if (u_Tex2Transform[2][2]!=0.0) {
        return texture2D(u_Tex2, proj2(pos));
    }
    else {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
}

vec4 planar(vec2 pos, vec2 outPos) {
    float intensity = getMaskedParameter(u_Intensity, outPos);
//    vec4 backgroundColor = texture2D(u_Tex0, proj0(pos));
    vec4 backgroundColor = getBackground(pos);//vec4(0.0, 0.0, 0.0, 1.0);

    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;

    if (dir.z==0.0) return backgroundColor;


    float maxZ = abs(intensity)*0.02;
    float ratio = (u_Tex0Dim.x/u_Tex0Dim.y);
    float dk = 2.0/u_Tex0Dim.y;
    vec3 step = dir * dk;
    bool heightMap = u_Tex1Transform[2][2]!=0.0;

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

//    float k = k1;
//    vec3 p = cameraPos + k*dir;

    float deltaZ, z;

    if (dir.z>0.0) {
        deltaZ = 2.0*maxZ/float(u_Count-1);
        z = -maxZ;
    }
    else {
        deltaZ = -2.0*maxZ/float(u_Count-1);
        z = maxZ;
    }

    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
    float h;
    bool stop = false;

    if (heightMap) {
        for(int i=0; i<u_Count; ++i) {
            float k = (z-cameraPos.z)/dir.z;
            vec2 p = (cameraPos + k*dir).xy;
            if (k>=0.0 && p.x>=-ratio && p.x<=ratio && p.y>=-1.0 && p.y<=1.0) { // optim: just use a non mirrored texture?
                color = texture2D(u_Tex1, proj1(p));
                h = height(intensity, color);
                if (abs(h-z) < 0.000005) {
                    color = texture2D(u_Tex0, proj0(p));
                    stop = true;
                    break;
                }
            }
            z += deltaZ;
        }
    }
    else {
        for(int i=0; i<u_Count; ++i) {
            float k = (z-cameraPos.z)/dir.z;
            vec2 p = (cameraPos + k*dir).xy;
            if (k>=0.0 && p.x>=-ratio && p.x<=ratio && p.y>=-1.0 && p.y<=1.0) { // optim: just use a non mirrored texture?
                color = texture2D(u_Tex0, proj0(p));
                h = height(intensity, color);
                if (abs(h-z) < 0.000005) {
                    stop = true;
                    break;
                }
            }
            z += deltaZ;
        }
    }

    if (stop) {
//    return color;
        float hRatio = maxZ==0.0 ? 1.0 : h/maxZ;
        if (u_ColorScheme <=50.0) {
            float darken = 1.0 + u_ColorScheme*0.02*hRatio;
            return color * vec4(darken, darken, darken, 1.0);
        }
        else {
            float darken = 1.0 + hRatio;
            float kkk = (u_ColorScheme-50.0)*0.02;
            vec4 col = color * vec4(darken, darken, darken, 1.0);
            return mix(col, vec4(darken*0.5, darken*0.5, darken*0.5, 1.0), kkk);
        }
    }

    return backgroundColor;

}


#include mainWithOutPos(planar)
