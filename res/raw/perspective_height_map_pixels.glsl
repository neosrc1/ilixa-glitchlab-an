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
uniform float u_Thickness;
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
//        return texture2D(u_Tex0, proj0(pos));//vec4(0.0, 0.0, 0.0, 1.0);
    }
}

vec3 cubeIntersection(vec3 center, float radius, vec3 origin, vec3 dir) {
    vec3 relOrigin = origin-center;
    float kOut = OOB;
    float kIn = 0.0;
    if (dir.x!=0.0) {
        float k1 = -(relOrigin.x-radius)/dir.x;
        float k2 = -(relOrigin.x+radius)/dir.x;
        kIn = max(kIn, min(k1, k2));
        kOut = min(kOut, max(k1, k2));
    }
    else if (abs(relOrigin.x)>radius) return vec3(OOB, OOB, OOB);

    if (dir.y!=0.0) {
        float k1 = -(relOrigin.y-radius)/dir.y;
        float k2 = -(relOrigin.y+radius)/dir.y;
        kIn = max(kIn, min(k1, k2));
        kOut = min(kOut, max(k1, k2));
    }
    else if (abs(relOrigin.y)>radius) return vec3(OOB, OOB, OOB);

    if (dir.z!=0.0) {
        float k1 = -(relOrigin.z-radius)/dir.z;
        float k2 = -(relOrigin.z+radius)/dir.z;
        kIn = max(kIn, min(k1, k2));
        kOut = min(kOut, max(k1, k2));
    }
    else if (abs(relOrigin.z)>radius) return vec3(OOB, OOB, OOB);

//    if (k1>k2) return vec3(OOB, OOB, OOB);
//    return origin + k1*dir;
    float k = kIn>0.0 ? kIn : kOut;
    if (k<=0.0 || kOut<kIn) return vec3(OOB, OOB, OOB);
    vec3 inters = origin + k*dir;
//    float err = 0.00001;
//    if (kIn<=0.0 || abs(inters.x-center.x)>radius+err || abs(inters.y-center.y)>radius+err || abs(inters.z-center.z)>radius+err) return vec3(OOB, OOB, OOB);
    return inters;
}

vec3 trailIntersection(vec3 center, float radius, float extraTrail, vec3 origin, vec3 dir) {
    vec3 relOrigin = origin-center;
    float kOut = OOB;
    float kIn = 0.0;
    if (dir.x!=0.0) {
        float k1 = -(relOrigin.x-radius)/dir.x;
        float k2 = -(relOrigin.x+radius)/dir.x;
        kIn = max(kIn, min(k1, k2));
        kOut = min(kOut, max(k1, k2));
    }
    else if (abs(relOrigin.x)>radius) return vec3(OOB, OOB, OOB);

    if (dir.y!=0.0) {
        float k1 = -(relOrigin.y-radius)/dir.y;
        float k2 = -(relOrigin.y+radius)/dir.y;
        kIn = max(kIn, min(k1, k2));
        kOut = min(kOut, max(k1, k2));
    }
    else if (abs(relOrigin.y)>radius) return vec3(OOB, OOB, OOB);

    if (dir.z!=0.0) {
        float k1 = -(relOrigin.z+radius)/dir.z;
        float k2 = -(relOrigin.z+(radius+extraTrail))/dir.z;
        kIn = max(kIn, min(k1, k2));
        kOut = min(kOut, max(k1, k2));
    }
    else if (abs(relOrigin.z)>radius) return vec3(OOB, OOB, OOB);

//    if (k1>k2) return vec3(OOB, OOB, OOB);
//    return origin + k1*dir;
    float k = kIn>0.0 ? kIn : kOut;
    if (k<=0.0 || kOut<kIn) return vec3(OOB, OOB, OOB);
    vec3 inters = origin + k*dir;
//    float err = 0.00001;
//    if (kIn<=0.0 || abs(inters.x-center.x)>radius+err || abs(inters.y-center.y)>radius+err || abs(inters.z-center.z)>radius+err) return vec3(OOB, OOB, OOB);
    return inters;
}

vec3 getCubeNormal(vec3 center, vec3 intersection) {
    vec3 d = intersection-center;
    if (abs(d.x)>abs(d.y) && abs(d.x)>abs(d.z)) {
        return vec3(sign(d.x), 0.0, 0.0);
    }
    else if (abs(d.y)>abs(d.z)) {
        return vec3(sign(d.y));
    }
    else {
        return vec3(sign(d.z));
    }
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
    float trailSize = u_Thickness*0.04;

int maxIter = 1000;
    while (intersected<1.0 && k<=k2 && maxIter>0) {
        // compute pixel center
        float indexX = (p.x+surfaceWidth/2.0)/ballSize;
        float indexY = (p.y+surfaceHeight/2.0)/ballSize;
        float fX = fract(indexX);
        float fY = fract(indexY);
        vec3 sphereCenter;

        if (fX>0.9999 && dir.x>0.0) sphereCenter.x = (ceil(indexX)+0.5)*ballSize;
        else if (fX<0.0001 && dir.x<0.0) sphereCenter.x = (floor(indexX)-0.5)*ballSize;
        else
        sphereCenter.x = (floor(indexX)+0.5)*ballSize;
        sphereCenter.x -= surfaceWidth/2.0;

        if (fY>0.9999 && dir.y>0.0) sphereCenter.y = (ceil(indexY)+0.5)*ballSize;
        else if (fY<0.0001 && dir.y<0.0) sphereCenter.y = (floor(indexY)-0.5)*ballSize;
        else
        sphereCenter.y = (floor(indexY)+0.5)*ballSize;
        sphereCenter.y -= surfaceHeight/2.0;
//        sphereCenter = p;

        // compute height and color
        vec4 hColor = heightMap ? texture2D(u_Tex1, proj1(sphereCenter.xy)): texture2D(u_Tex0, proj0(sphereCenter.xy));
        float height = height(intensity, hColor);
        sphereCenter.z = height;

        // compute sphere intersection
        if (/*abs(sphereCenter.z-p.z)<ballSize &&*/ abs(sphereCenter.x)<surfaceWidth/2.0 && abs(sphereCenter.y)<surfaceHeight/2.0) {
            vec3 intersection = cubeIntersection(sphereCenter, ballSize/2.0, cameraPos, dir);
            float trailAlpha = 1.0;
            if (intersection.x==OOB) {
                intersection = trailIntersection(sphereCenter, ballSize/2.0, trailSize, cameraPos, dir);
                if (intersection.x!=OOB) {
                    trailAlpha = 1.0/(1.0+1.0*(height-ballSize/2.0-intersection.z)/trailSize);
                }
            }

            if (intersection.x!=OOB) {
                vec4 col;
                if (u_ColorScheme==0.0) col = texture2D(u_Tex0, proj0(sphereCenter.xy));
                else if (u_ColorScheme==100.0) col = texture2D(u_Tex0, proj0(intersection.xy));
                else col = mix(texture2D(u_Tex0, proj0(sphereCenter.xy)), texture2D(u_Tex0, proj0(intersection.xy)), u_ColorScheme*0.01);

                col.a *= trailAlpha;
//            if (intersection.z<height-ballSize/2.0) {
//                float trailSize = ballSize*5.0 - ballSize/2.0;
////                col = vec4(1.0, 0.0, 0.0, 1.0);
//                col.a *= 1.0/(1.0+1.0*(height-ballSize/2.0-intersection.z)/trailSize);
//            }
                vec4 sampled = col * vec4(u_Color3.rgb*2.0, u_Color3.a);
                if (length(u_Color2.rgb)!=0.0) { // light source
                    vec3 normal = getCubeNormal(sphereCenter, intersection);

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
//                intersected = 1.0; // break condition
//                vec4 sampled = texture2D(u_Tex0, proj0(sphereCenter.xy));
//                outColor = intersected==0.0 ? sampled : mix(outColor, sampled, 0.05/(intersected+0.2));
//                intersected += 0.2; // break condition

            }

        }

//        if (abs(sphereCenter.z-p.z)<ballSize) {
//        if (sphereCenter.z > p.z) {
//            outColor = texture2D(u_Tex0, proj0(sphereCenter.xy));
//            intersected = 1.0; // break condition
//        }

        // advance
        vec2 next = sphereCenter.xy + nextLines;
        vec2 deltaK = (next-p.xy)/dir.xy;
        float minK = min(deltaK.x, deltaK.y); //if (minK<0.0001) minK = max(deltaK.x, deltaK.y);
        k += minK;
        p += minK*dir;
        --maxIter;
    }
//if (maxIter<=0) return vec4(0.0, 0.0, 1.0, 1.0);
    return mix(color, vec4(outColor.rgb, color.a), outColor.a);


//    return mix(mix(vec4(length(cross(dir, vec3(0.0, 0.0, 1.0))), 1.0-length(cross(dir, vec3(0.0, 0.0, 1.0))), 0.0, 1.0), getBackground(pos), 0.5), wireColor, intersected);
}

#include mainWithOutPos(balls)
