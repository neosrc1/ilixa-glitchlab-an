precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include tex(1)
#include tex(2)

#define OOB 1e9

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
uniform vec4 u_Color2;
uniform vec4 u_Color3;

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
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
}

vec3 sphereIntersection(vec3 center, float radius, vec3 origin, vec3 dir) {
    vec3 relOrigin = origin-center;
    float a = dot(dir, dir);
    float b = 2.0*dot(dir, relOrigin);
    float c = dot(relOrigin, relOrigin) - radius*radius;
    float delta = b*b - 4.0*a*c;
    if (delta>=0.0) {
        float sqrtDelta = sqrt(delta);
        float l1 = (-b - sqrtDelta) / (2.0*a);
        float l2 = (-b + sqrtDelta) / (2.0*a);
        float l = l1>0.0 ? l1 : (l2>0.0 ? l2 : -1.0);
        if (l>0.0) {
            return center+origin + l*dir;
        }
    }
    return vec3(OOB, OOB, OOB);
}

vec4 balls(vec2 pos, vec2 outPos) {
    float intensity = getMaskedParameter(u_Intensity, outPos);
    vec4 backgroundColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));

//    float d = length(pos); // semi-working fisheye
//    if (d!=0.0) {
//        vec2 pn = normalize(pos);
//        dir = mat3(pn.x, pn.y, 0.0, pn.y, -pn.x, 0.0, 0.0, 0.0, 1.0) * vec3(sin(d*M_PI/2.0), 0.0, cos(d*M_PI/2.0));
//    }

    dir = mat3(u_InverseModel3DTransform) * dir;

    bool heightMap = u_Tex1Transform[2][2]!=0.0;

    float maxZ = abs(intensity)*0.02;
    float ratio = heightMap ? (u_Tex1Dim.x/u_Tex1Dim.y) : (u_Tex0Dim.x/u_Tex0Dim.y);
    float dk = heightMap ? 2.0/u_Tex1Dim.y : 2.0/u_Tex0Dim.y;
//    vec3 step = dir * dk;

    float u_Resolution = u_Count;
    float ballSize = 2.0/u_Resolution;
    maxZ += ballSize;
    float surfaceWidth = round((2.0*ratio)/ballSize)*ballSize;
    float surfaceHeight = 2.0;

    float k1 = 0.0;
    float k2 = 100000000.0;

    if (dir.x!=0.0) {
        float s = sign(dir.x);
        float k3 = (-s*surfaceWidth/2.0-cameraPos.x)/dir.x;
        float k4 = (s*surfaceWidth/2.0-cameraPos.x)/dir.x;
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

    vec4 color = getBackground(outPos); //backgroundColor;
    float h = 0.0;
    float dz = 0.0;
    float prevDz;
    vec4 prevColor;
    float prevH;
    bool stop;

    float strideX = sign(dir.x) * ballSize;
    float strideY = sign(dir.y) * ballSize;

    float intersected = 0.0;

    vec4 outColor = vec4(0.0, 0.0, 0.0, 0.0);//color; //backgroundColor;
    int maxIter = 500;
    float minK = ballSize/4.0;
    vec3 step = minK*dir;
//    float kk = minK/length(vec2(dir));
//    vec3 step = kk*dir;
    while (intersected<1.0 && k<=k2 && maxIter>0) {
        // compute height and color
        vec4 hColor = heightMap ? texture2D(u_Tex1, proj1(p.xy)): texture2D(u_Tex0, proj0(p.xy));
        float height = height(intensity, hColor);

        if (height > p.z) {
            outColor = texture2D(u_Tex0, proj0(p.xy));
            intersected = 1.0; // break condition
        }

        // advance
        k += minK;
        p += step;
        --maxIter;
    }

    return mix(color, vec4(outColor.rgb, color.a), outColor.a);//return outColor;
}

#include mainWithOutPos(balls)