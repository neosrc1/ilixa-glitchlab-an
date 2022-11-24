precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include tex(1)
#include tex(2)

uniform float u_Count;
uniform float u_Intensity;
uniform float u_ColorScheme;
uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;

uniform float u_Thickness;
uniform float u_Blur;
uniform float u_Gamma;
uniform float u_Shadows;
uniform float u_Specular;
uniform float u_SurfaceSmoothness;
uniform float u_NormalSmoothing;
uniform float u_LSDistance;
uniform vec4 u_Color1;

float height(float intensity, vec4 color) {
    return intensity*0.04* ((color.r + color.g + color.b)/3.0 - 0.5);
}

float round(float x) { return floor(x+0.5); }

bool close(float a, float b) {
    return abs(a-b) < 0.00001;
}

vec4 getBackground(vec2 pos) {
    if (u_Tex2Transform[2][2]!=0.0) {
        return texture2D(u_Tex2, proj2(pos));
    }
    else {
        return texture2D(u_Tex0, proj0(pos));
        //return vec4(0.0, 0.0, 0.0, 1.0);
    }
}

float intersectX(vec3 pos, vec3 dir, vec3 cameraPos, vec3 cameraDir, float intensity, bool heightMap) {
    vec4 color = heightMap ? texture2D(u_Tex1, proj1(pos.xy)): texture2D(u_Tex0, proj0(pos.xy));
    float h = height(intensity, color);
    //h = length(cross(dir, vec3(0.0, 0.0, h)));

    float dist = dot(cameraDir, pos-cameraPos);
    float t = u_Thickness*0.0001;
    float b = u_Blur*0.001;
    float maxDist = (t+b)*dist;
    //maxDist /= length(cross(normalize(dir.xz), vec2(0.0, 1.0)));
//    maxDist /= abs(normalize(dir.xz).x);
    maxDist /= abs(normalize(cameraPos.xz-vec2(pos.x, h)).x);
//    h = length(cross(dir, vec3(0.0, 0.0, abs(pos.z-h))));
//    float proxim = h/maxDist;
    float proxim = abs(pos.z-h) / maxDist;
    if (proxim>1.0) return 0.0;
    return 1.0-pow(smoothstep(t/(t+b), 1.0, proxim), 0.5);
}

float intersectY(vec3 pos, vec3 dir, vec3 cameraPos, vec3 cameraDir, float intensity, bool heightMap) {
    vec4 color = heightMap ? texture2D(u_Tex1, proj1(pos.xy)): texture2D(u_Tex0, proj0(pos.xy));
    float h = height(intensity, color);
    //h = length(cross(dir, vec3(0.0, 0.0, h)));

    float dist = dot(cameraDir, pos-cameraPos);
    float t = u_Thickness*0.0001;
    float b = u_Blur*0.001;
    float maxDist = (t+b)*dist;
//    maxDist /= length(cross(normalize(dir.yz), vec2(0.0, 1.0)));
//    maxDist /= abs(normalize(dir.yz).x);
    maxDist /= abs(normalize(cameraPos.yz-vec2(pos.y, h)).x);
//    h = length(cross(dir, vec3(0.0, 0.0, abs(pos.z-h))));
//    float proxim = h/maxDist;
    float proxim = abs(pos.z-h) / maxDist;
    if (proxim>1.0) return 0.0;
    return 1.0-pow(smoothstep(t/(t+b), 1.0, proxim), 0.5);
}

//float intersectY2(vec3 pos, vec3 dir, vec3 cameraPos, vec3 cameraDir, float intensity, bool heightMap) {
//    vec4 color = texture2D(u_Tex0, proj0(pos.xy));
//    float h = height(intensity, color);
//    //h = length(cross(dir, vec3(0.0, 0.0, h)));
//
//    float dist = dot(cameraDir, pos-cameraPos);
//    float t = u_Thickness*0.0001;
//    float b = u_Blur*0.001;
//    float maxDist = (t+b)*dist;
//    float proxim = abs(pos.z-h) / maxDist;
//    if (proxim>1.0) {
//        maxDist /= abs(normalize(dir.yz).x);
//        proxim = abs(pos.z-h) / maxDist;
//        if (proxim>1.0) return 0.0;
//        else return 0.5;
//    }
//    return 1.0-pow(smoothstep(t/(t+b), 1.0, proxim), 0.5);
//}
//
//float intersectXY(vec3 pos, vec3 dir, vec3 cameraPos, vec3 cameraDir, float intensity, bool heightMap) {
//    vec4 color = heightMap ? texture2D(u_Tex1, proj1(pos.xy)): texture2D(u_Tex0, proj0(pos.xy));
//    float h = height(intensity, color);
//    vec3 center = vec3(pos.xy, h);
//    float radius = u_Thickness*0.0001 * length(cameraPos-center);
//    vec3 relOrigin = cameraPos-center;
//    float a = dot(dir, dir);
//    float b = 2.0*dot(dir, relOrigin);
//    float c = dot(relOrigin, relOrigin) - radius*radius;
//    float delta = b*b - 4.0*a*c;
//    if (delta>=0.0) {
//        float sqrtDelta = sqrt(delta);
//        float l1 = (-b - sqrtDelta) / (2.0*a);
//        float l2 = (-b + sqrtDelta) / (2.0*a);
//        float l = l1>0.0 ? l1 : (l2>0.0 ? l2 : -1.0);
//        if (l>0.0) {
//            return 1.0; //return center+cameraPos + l*dir;
//        }
//    }
//    return 0.0;
//}

vec4 planar(vec2 pos, vec2 outPos) {
    float intensity = getMaskedParameter(u_Intensity, outPos);
    vec4 backgroundColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;
    vec3 cameraDir = normalize(vec3(0.0, 0.0, -1.0));
    cameraDir = mat3(u_InverseModel3DTransform) * cameraDir;

    bool heightMap = u_Tex1Transform[2][2]!=0.0;

    float maxZ = abs(intensity)*0.02;
    float ratio = heightMap ? (u_Tex1Dim.x/u_Tex1Dim.y) : (u_Tex0Dim.x/u_Tex0Dim.y);
    float dk = heightMap ? 2.0/u_Tex1Dim.y : 2.0/u_Tex0Dim.y;
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

    float maxZ2 = maxZ+0.0001; // prevent flickering on edge case
    if (dir.z!=0.0) {
        float s = sign(dir.z);
        float k3 = (-s*maxZ2-cameraPos.z)/dir.z;
        float k4 = (s*maxZ2-cameraPos.z)/dir.z;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    if (k1>k2) return getBackground(outPos); //backgroundColor;

    float k = k1;
    vec3 p = cameraPos + k*dir;

    vec4 color = backgroundColor;
    float h = 0.0;
    float dz = 0.0;
    float prevDz;
    vec4 prevColor;
    float prevH;
    bool stop;

    float strideX = ratio*2.0/u_Count;
    float countY = round(2.0/strideX);
    float strideY = 2.0/countY;

    float intersected = 0.0;

    if (false&&heightMap) {
            //h = height(intensity, texture2D(u_Tex1, proj1(p.xy)));
    }
    else {
        float yPos = (p.y+1.0)/strideY;
        float yIndex = round(yPos);
        if (close(yPos, yIndex)) {
            intersected += intersectY(p, dir, cameraPos, cameraDir, intensity, heightMap);
        }

        if (dir.y!=0.0) {
            float advanceY = (sign(dir.y)>0.0 ? ceil(yPos)-yPos : floor(yPos)-yPos) * strideY;
//            float advanceY = (sign(dir.y)>0.0 ? floor(yPos)-yPos : ceil(yPos)-yPos) * strideY;
            float deltaK = advanceY/dir.y;
            k += deltaK;
            p += deltaK*dir;

            float deltaY = sign(dir.y) * strideY;
            deltaK = deltaY/dir.y;
            while (abs(p.y)<=1.0 && k<=k2) {
                intersected += intersectY(p, dir, cameraPos, cameraDir, intensity, heightMap);
                if (intersected>=1.0) break;
                k += deltaK;
                p += deltaK*dir;
            }
        }

        k = k1;
        p = cameraPos + k*dir;

        float xPos = (p.x+1.0)/strideX;
        float xIndex = round(xPos);
        if (close(xPos, xIndex)) {
            intersected += intersectX(p, dir, cameraPos, cameraDir, intensity, heightMap);
        }

        if (dir.x!=0.0) {
            float advanceX = (sign(dir.x)>0.0 ? ceil(xPos)-xPos : floor(xPos)-xPos) * strideX;
            float deltaK = advanceX/dir.x;
            k += deltaK;
            p += deltaK*dir;

            float deltaX = sign(dir.x) * strideX;
            deltaK = deltaX/dir.x;
            while (abs(p.x)<=ratio && k<=k2) {
                intersected += intersectX(p, dir, cameraPos, cameraDir, intensity, heightMap);
                if (intersected>=1.0) break;
                k += deltaK;
                p += deltaK*dir;
            }
        }
    }

    vec4 wireColor = u_Color1;
    return mix(mix(vec4(0.0, 0.0, 1.0, 1.0), getBackground(outPos), 1.0), wireColor, intersected);
//    return mix(mix(vec4(length(cross(dir, vec3(0.0, 0.0, 1.0))), 1.0-length(cross(dir, vec3(0.0, 0.0, 1.0))), 0.0, 1.0), getBackground(pos), 0.5), wireColor, intersected);
}

#include mainWithOutPos(planar)
