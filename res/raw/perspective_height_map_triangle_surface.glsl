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

uniform float u_Reflectivity;
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

mat3 trianglesIntersection(vec2 p, float step, vec3 origin, vec3 dir, float intensity, bool heightMap) {
    // compute height and color
    vec2 s = vec2(step, 0.0);
    vec2 p11 = p+s.xx;

    vec4 c00 = heightMap ? texture2D(u_Tex1, proj1(p)): texture2D(u_Tex0, proj0(p));
    float h00 = height(intensity, c00);
    vec4 c10 = heightMap ? texture2D(u_Tex1, proj1(p+s)): texture2D(u_Tex0, proj0(p+s));
    float h10 = height(intensity, c10);
    vec4 c01 = heightMap ? texture2D(u_Tex1, proj1(p+s.yx)): texture2D(u_Tex0, proj0(p+s.yx));
    float h01 = height(intensity, c01);
    vec4 c11 = heightMap ? texture2D(u_Tex1, proj1(p11)): texture2D(u_Tex0, proj0(p11));
    float h11 = height(intensity, c11);

    float dzx1 = (h10-h00)/step;
    float dzy1 = (h01-h00)/step;
    float k1 = (h00-origin.z + (origin.x-p.x)*dzx1 + (origin.y-p.y)*dzy1) / (dir.z - dir.x*dzx1 - dir.y*dzy1);

    float dzx2 = -(h01-h11)/step;
    float dzy2 = -(h10-h11)/step;
    float k2 = (h11-origin.z + (origin.x-p11.x)*dzx2 + (origin.y-p11.y)*dzy2) / (dir.z - dir.x*dzx2 - dir.y*dzy2);

    vec3 normal = vec3(0.0, 0.0, 0.0);
    vec3 intersection = vec3(OOB, OOB, OOB);

    if (k1>0.0) {
        intersection = origin + k1*dir;
        vec2 relInt = intersection.xy-p.xy;
        if (relInt.x>=0.0 && relInt.x<=step && relInt.y>=0.0 && relInt.y<=step
            && step-relInt.x>=relInt.y) {
            normal = normalize(cross(vec3(step, 0.0, h10-h00), vec3(0.0, step, h01-h00)));
            return mat3(intersection, normal, vec3(0.0, 0.0, 0.0));
        }
    }
    if (k2>0.0) {
        intersection = origin + k2*dir;
        vec2 relInt = intersection.xy-p.xy;
        if (relInt.x>=0.0 && relInt.x<=step && relInt.y>=0.0 && relInt.y<=step
        && step-relInt.x<=relInt.y) {
            normal = normalize(cross(vec3(-step, 0.0, h01-h11), vec3(0.0, -step, h10-h11)));
            return mat3(intersection, normal, vec3(0.0, 0.0, 0.0));
        }
    }

    return mat3(vec3(OOB, OOB, OOB), vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0));
}

vec4 triangles(vec2 pos, vec2 outPos) {
    float intensity = getMaskedParameter(u_Intensity, outPos);
    vec4 backgroundColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;

    if (dir.x==0.0) { dir.x=0.00001; dir = normalize(dir); } // ugly hack to avoid black cross in the middle on certain devices
    if (dir.y==0.0) { dir.y=0.00001; dir = normalize(dir); }

//    vec3 cameraDir = normalize(vec3(0.0, 0.0, -1.0));
//    cameraDir = mat3(u_InverseModel3DTransform) * cameraDir;

    bool heightMap = u_Tex1Transform[2][2]!=0.0;

    float maxZ = abs(intensity)*0.02;
    float ratio = heightMap ? (u_Tex1Dim.x/u_Tex1Dim.y) : (u_Tex0Dim.x/u_Tex0Dim.y);
    float dk = heightMap ? 2.0/u_Tex1Dim.y : 2.0/u_Tex0Dim.y;
    vec3 step = dir * dk;

    float u_Resolution = u_Count;
    float squareSize = 2.0/u_Resolution;
    maxZ += squareSize;
    float surfaceWidth = round((2.0*ratio)/squareSize)*squareSize;
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

    float intersected = 0.0;

    vec4 outColor = vec4(0.0, 0.0, 0.0, 0.0);//color; //backgroundColor;
    vec2 nextLines = sign(dir.xy)*squareSize/2.0; //vec2(sign(dir.x)*squareSize, sign(dir.y)*squareSize)/2.0;
int maxIter = 1000;
    while (intersected<1.0 && k<=k2 && maxIter>0) {
        // compute pixel center
        float indexX = (p.x+surfaceWidth/2.0)/squareSize;
        float indexY = (p.y+surfaceHeight/2.0)/squareSize;
        float fX = fract(indexX);
        float fY = fract(indexY);
        vec2 squareCenter;

        if (fX>0.9999 && dir.x>0.0) squareCenter.x = (ceil(indexX)+0.5)*squareSize;
        else if (fX<0.0001 && dir.x<0.0) squareCenter.x = (floor(indexX)-0.5)*squareSize;
        else
        squareCenter.x = (floor(indexX)+0.5)*squareSize;
        squareCenter.x -= surfaceWidth/2.0;

        if (fY>0.9999 && dir.y>0.0) squareCenter.y = (ceil(indexY)+0.5)*squareSize;
        else if (fY<0.0001 && dir.y<0.0) squareCenter.y = (floor(indexY)-0.5)*squareSize;
        else
        squareCenter.y = (floor(indexY)+0.5)*squareSize;
        squareCenter.y -= surfaceHeight/2.0;
//        squareCenter = p;

        vec2 bottomLeft = squareCenter - vec2(squareSize, squareSize)/2.0;

        // compute triangles intersection
        mat3 intersection = trianglesIntersection(bottomLeft, squareSize, p, dir, intensity, heightMap);
        if (intersection[0][0]!=OOB /*&& indexY>0.0 && indexY<u_Resolution*/) {
            vec4 col = texture2D(u_Tex0, proj0(squareCenter.xy));
            vec4 sampled = col * vec4(u_Color3.rgb*2.0, u_Color3.a);
            if (length(u_Color2.rgb)!=0.0) { // light source
                vec3 normal = intersection[1];

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
            if (u_Reflectivity!=0.0) {
                vec3 normal = intersection[1];
                vec3 reflectDir = reflect(dir, normal);
                vec2 backPos = reflectDir.xy / reflectDir.z;
                vec4 reflected = getBackground(backPos);

                float lum = (reflected.r+reflected.g+reflected.b)*0.3333333;
                float k = min(1.0, lum*u_Reflectivity*0.1);
                sampled = mix(u_Color2, reflected, k);
//                sampled = mix(sampled, reflected, u_Reflectivity*0.01);
            }

            outColor =  intersected==0.0 ? sampled : vec4(mix(outColor.rgb, sampled.rgb, intersected/(intersected+sampled.a)), outColor.a+(1.0-outColor.a)*sampled.a);
            intersected += sampled.a;
//                intersected = 1.0; // break condition
//                vec4 sampled = texture2D(u_Tex0, proj0(squareCenter.xy));
//                outColor = intersected==0.0 ? sampled : mix(outColor, sampled, 0.05/(intersected+0.2));
//                intersected += 0.2; // break condition

        }

//        if (abs(squareCenter.z-p.z)<squareSize) {
//        if (squareCenter.z > p.z) {
//            outColor = texture2D(u_Tex0, proj0(squareCenter.xy));
//            intersected = 1.0; // break condition
//        }

        // advance
        if (dir.x==0.0 && dir.y==0.0) break;
        vec2 next = squareCenter.xy + nextLines;
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

#include mainWithOutPos(triangles)
