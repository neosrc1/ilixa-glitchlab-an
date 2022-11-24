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

uniform float u_Blur;
uniform float u_Gamma;
uniform float u_Shadows;
uniform float u_Specular;
uniform float u_SurfaceSmoothness;
uniform float u_NormalSmoothing;
uniform float u_LSDistance;
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
            return origin + l*dir;
        }
    }
    return vec3(OOB, OOB, OOB);
}

vec4 balls(vec2 pos, vec2 outPos) {
    float intensity = getMaskedParameter(u_Intensity, outPos);
    vec4 backgroundColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;

    bool heightMap = u_Tex1Transform[2][2]!=0.0;

    float maxZ = abs(intensity)*0.02;
    float ratio = heightMap ? (u_Tex1Dim.x/u_Tex1Dim.y) : (u_Tex0Dim.x/u_Tex0Dim.y);
    float dk = heightMap ? 2.0/u_Tex1Dim.y : 2.0/u_Tex0Dim.y;
    vec3 step = dir * dk;

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

    if (k1>k2) return getBackground(outPos);
    //    if (k1>k2) return backgroundColor;

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
    vec2 nextLines = sign(dir.xy)*ballSize/2.0; //vec2(sign(dir.x)*ballSize, sign(dir.y)*ballSize)/2.0;
    int maxIter = 1000;
    while (intersected<1.0 && k<=k2 && maxIter>0) {
        // compute pixel center
        float indexX = (p.x+surfaceWidth/2.0)/ballSize;
        float indexY = (p.y+surfaceHeight/2.0)/ballSize;
        float fX = fract(indexX);
        float fY = fract(indexY);
        vec3 sphereCenter;

        if (fX>0.9999999 && dir.x>0.0) sphereCenter.x = (ceil(indexX)+0.5)*ballSize;
        else if (fX<0.0000001 && dir.x<0.0) sphereCenter.x = (floor(indexX)-0.5)*ballSize;
        else sphereCenter.x = round(indexX)*ballSize;
        sphereCenter.x += surfaceWidth/2.0;

        if (fY>0.9999999 && dir.y>0.0) sphereCenter.y = (ceil(indexY)+0.5)*ballSize;
        else if (fY<0.0000001 && dir.y<0.0) sphereCenter.y = (floor(indexY)-0.5)*ballSize;
        else sphereCenter.y = round(indexY)*ballSize;
        sphereCenter.y -= surfaceHeight/2.0;
        sphereCenter = p;
        //        sphereCenter = p;

        // compute height and color
        vec4 hColor = heightMap ? texture2D(u_Tex1, proj1(sphereCenter.xy)): texture2D(u_Tex0, proj0(sphereCenter.xy));
        float height = height(intensity, hColor);
        sphereCenter.z = height;

        // compute sphere intersection
        if (/*abs(sphereCenter.z-p.z)<ballSize &&*/ abs(sphereCenter.x)<surfaceWidth/2.0 && abs(sphereCenter.y)<surfaceHeight/2.0) {
            vec3 intersection = sphereIntersection(sphereCenter, ballSize/2.0, cameraPos, dir);

            if (intersection.x!=OOB) {
                vec4 col = texture2D(u_Tex0, proj0(sphereCenter.xy));
                vec4 sampled = col * vec4(u_Color3.rgb*2.0, u_Color3.a);
                if (length(u_Color2.rgb)!=0.0) { // light source
                    vec3 normal = intersection-sphereCenter;

                    if (length(normal)>0.0) {
                        float alpha = sampled.a;
                        normal = normalize(normal);
                        vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
                        sampled += col*vec4(u_Color2.rgb*2.0, 1.0) * clamp(dot(lightDir, normal), 0.0, 1.0);

                        if (u_Specular!=0.0) {
                            vec3 reflectLightDir = reflect(lightDir, normal);
                            float spec = u_Specular*0.01;
                            vec4 specularColor = u_Color2 * (u_Specular<25.0?u_Specular*0.04:1.0) * pow(clamp(dot(dir, reflectLightDir), 0.0, 1.0), 10.0-u_Specular*0.1);//(dot(dir, reflectLightDir)) * vec4(spec, spec, spec, 1.0);
                            sampled = sampled + specularColor;
                        }
                        sampled.a = alpha;
                    }
                }

                outColor =  intersected==0.0 ? sampled : vec4(mix(outColor.rgb, sampled.rgb, intersected/(intersected+sampled.a)), outColor.a+(1.0-outColor.a)*sampled.a);
                intersected += sampled.a;


            }

        }


        // advance
        vec2 next = sphereCenter.xy + nextLines;
        vec2 deltaK = (next-p.xy)/dir.xy;
        float minK = ballSize/4.0; //min(deltaK.x, deltaK.y);
        k += minK;
        p += minK*dir;
        --maxIter;
    }
    return mix(color, vec4(outColor.rgb, color.a), outColor.a);


    //    return mix(mix(vec4(length(cross(dir, vec3(0.0, 0.0, 1.0))), 1.0-length(cross(dir, vec3(0.0, 0.0, 1.0))), 0.0, 1.0), getBackground(pos), 0.5), wireColor, intersected);
}

#include mainWithOutPos(balls)

/*precision highp float;
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
        return texture2D(u_Tex0, proj0(pos));//vec4(0.0, 0.0, 0.0, 1.0);
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
    dir = mat3(u_InverseModel3DTransform) * dir;
//    vec3 cameraDir = normalize(vec3(0.0, 0.0, -1.0));
//    cameraDir = mat3(u_InverseModel3DTransform) * cameraDir;

    bool heightMap = u_Tex1Transform[2][2]!=0.0;

    float maxZ = abs(intensity)*0.02;
    float ratio = heightMap ? (u_Tex1Dim.x/u_Tex1Dim.y) : (u_Tex0Dim.x/u_Tex0Dim.y);
    float dk = heightMap ? 2.0/u_Tex1Dim.y : 2.0/u_Tex0Dim.y;
    vec3 step = dir * dk;

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

    vec4 color = backgroundColor;
    float h = 0.0;
    float dz = 0.0;
    float prevDz;
    vec4 prevColor;
    float prevH;
    bool stop;

    float strideX = sign(dir.x) * ballSize;
    float strideY = sign(dir.y) * ballSize;

    float intersected = 0.0;

    vec4 outColor = backgroundColor;
    vec2 nextLines = vec2(sign(dir.x)*ballSize, sign(dir.y)*ballSize)/2.0;
int maxIter = 500;
    while (intersected<1.0 && k<=k2 && maxIter>0) {
        // compute pixel center
        float indexX = (p.x+surfaceWidth/2.0)/ballSize;
        float indexY = (p.y+surfaceHeight/2.0)/ballSize;
        float fX = fract(indexX);
        float fY = fract(indexY);
        vec3 sphereCenter;

        if (fX>0.9999999 && dir.x>0.0) sphereCenter.x = (ceil(indexX)+0.5)*ballSize;
        else if (fX<0.0000001 && dir.x<0.0) sphereCenter.x = (floor(indexX)-0.5)*ballSize;
        else sphereCenter.x = round(indexX)*ballSize;
        sphereCenter.x += surfaceWidth/2.0;

        if (fY>0.9999999 && dir.y>0.0) sphereCenter.y = (ceil(indexY)+0.5)*ballSize;
        else if (fY<0.0000001 && dir.y<0.0) sphereCenter.y = (floor(indexY)-0.5)*ballSize;
        else sphereCenter.y = round(indexY)*ballSize;
        sphereCenter.y -= surfaceHeight/2.0;
        sphereCenter = p;

        // compute height and color
        vec4 hColor = heightMap ? texture2D(u_Tex1, proj1(sphereCenter.xy)): texture2D(u_Tex0, proj0(sphereCenter.xy));
        float height = height(intensity, hColor);
        sphereCenter.z = height;

        // compute sphere intersection
//        vec3 intersection = sphereIntersection(sphereCenter, ballSize/2.0, cameraPos, dir);
//
//        if (intersection.x!=OOB) {
//            outColor = texture2D(u_Tex0, proj0(sphereCenter.xy));
//            intersected = 1.0; // break condition
//        }

//        if (abs(sphereCenter.z-p.z)<ballSize) {
        if (sphereCenter.z > p.z) {
            outColor = texture2D(u_Tex0, proj0(sphereCenter.xy));
            intersected = 1.0; // break condition
        }

        // advance
        vec2 next = sphereCenter.xy + nextLines;
        vec2 deltaK = (next-p.xy)/dir.xy;
        float minK = ballSize/4.0; //min(deltaK.x, deltaK.y);
        k += minK;
        p += minK*dir;
        --maxIter;
    }

    return outColor;

//    float yPos = (p.y+1.0)/strideY;
//    float yIndex = round(yPos);
//    if (close(yPos, yIndex)) {
//        intersected += intersectY(p, dir, cameraPos, cameraDir, intensity, heightMap);
//    }
//
//    if (dir.y!=0.0) {
//        float advanceY = (sign(dir.y)>0.0 ? ceil(yPos)-yPos : floor(yPos)-yPos) * strideY;
////            float advanceY = (sign(dir.y)>0.0 ? floor(yPos)-yPos : ceil(yPos)-yPos) * strideY;
//        float deltaK = advanceY/dir.y;
//        k += deltaK;
//        p += deltaK*dir;
//
//        float deltaY = sign(dir.y) * strideY;
//        deltaK = deltaY/dir.y;
//        while (abs(p.y)<=1.0 && k<=k2) {
//            intersected += intersectY(p, dir, cameraPos, cameraDir, intensity, heightMap);
//            if (intersected>=1.0) break;
//            k += deltaK;
//            p += deltaK*dir;
//        }
//    }
//
//    k = k1;
//    p = cameraPos + k*dir;
//
//    float xPos = (p.x+1.0)/strideX;
//    float xIndex = round(xPos);
//    if (close(xPos, xIndex)) {
//        intersected += intersectX(p, dir, cameraPos, cameraDir, intensity, heightMap);
//    }
//
//    if (dir.x!=0.0) {
//        float advanceX = (sign(dir.x)>0.0 ? ceil(xPos)-xPos : floor(xPos)-xPos) * strideX;
//        float deltaK = advanceX/dir.x;
//        k += deltaK;
//        p += deltaK*dir;
//
//        float deltaX = sign(dir.x) * strideX;
//        deltaK = deltaX/dir.x;
//        while (abs(p.x)<=ratio && k<=k2) {
//            intersected += intersectX(p, dir, cameraPos, cameraDir, intensity, heightMap);
//            if (intersected>=1.0) break;
//            k += deltaK;
//            p += deltaK*dir;
//        }
//    }


//    return mix(mix(vec4(length(cross(dir, vec3(0.0, 0.0, 1.0))), 1.0-length(cross(dir, vec3(0.0, 0.0, 1.0))), 0.0, 1.0), getBackground(pos), 0.5), wireColor, intersected);
}

#include mainWithOutPos(balls)*/
