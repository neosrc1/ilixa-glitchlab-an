precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include tex(1)
#include tex(2)

#define OOB 1e9
#define SMALL_NUM 0.00001

uniform float u_Count;
uniform float u_Intensity;
uniform float u_ColorScheme;
uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;
uniform mat3 u_InverseViewTransform;

uniform float u_Reflectivity;
uniform float u_Glow;
uniform float u_Thickness;
uniform float u_Gamma;
uniform float u_Shadows;
uniform float u_Specular;
uniform float u_SurfaceSmoothness;
uniform float u_NormalSmoothing;
uniform float u_LSDistance;
uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform vec4 u_Color3;
uniform int u_BackgroundMode;

vec4 sphereMap(vec3 dir) {
    vec3 n = normalize(dir);
    float alpha = getVecAngle(n.xz);
    float beta = asin(n.y);
    float ratio = (u_Tex2Dim.x/u_Tex2Dim.y);
    float nX = 2.0;
    float nY = 1.0;
    return texture2D(u_Tex2, vec2(-alpha/M_PI*0.5*nX, 0.5+nY*beta/M_PI));
}

vec4 planeMap(vec3 dir) {
    vec2 pos = vec2(-dir.x/dir.z * u_Tex2Dim.y/u_Tex2Dim.x, -dir.y/dir.z)*0.5 + vec2(0.5, 0.5);
    float m = max(abs(pos.x), abs(pos.y));
    float darken = 4.0/max(4.0, m);
    return texture2D(u_Tex2, pos)*vec4(darken, darken, darken, 1.0);
}

vec4 boxMap(vec3 dir) {
    float ratio = (u_Tex2Dim.y/u_Tex2Dim.x);
    float X = 0.5;
    float Y = 0.5;
    if (abs(dir.y)>abs(dir.z)*ratio && abs(dir.y)>abs(dir.x)*ratio) {
        X += -dir.x/dir.y*0.5;
        Y += -dir.z/dir.y*0.5;
    }
    else if (abs(dir.x)<abs(dir.z)) {
        X += dir.x/abs(dir.z)*ratio*0.5 * -sign(dir.z);
        Y += dir.y/abs(dir.z)*0.5;
    }
    else {
        X += dir.z/abs(dir.x)*ratio*0.5 * -sign(dir.x);
        Y += dir.y/abs(dir.x)*0.5;
    }
    return texture2D(u_Tex2, vec2(X, Y));
}

vec4 backgroundForReflection(vec3 dir) {
    if (u_Tex2Transform[2][2]!=0.0) {
        if (u_BackgroundMode==1) return planeMap(dir);
        else if (u_BackgroundMode==2) return boxMap(dir);
        else if (u_BackgroundMode==3) {
           dir = mat3(u_Model3DTransform) * dir;

//            dir.xy = mat2(u_InverseViewTransform) * -dir.xy/dir.z;
           dir.xy = (u_InverseViewTransform * vec3(-dir.xy/dir.z, 1.0)).xy;
//            dir.xy = (u_InverseViewTransform * vec3(dir.xy, 1.0)).xy;
//            dir.xy = -dir.xy/dir.z;
           dir.z = sign(dir.z);

           float ratio = (u_Tex2Dim.y/u_Tex2Dim.x);
           float X = 0.0;
           float Y = 0.0;
           if (abs(dir.y)>abs(dir.z)*ratio && abs(dir.y)>abs(dir.x)*ratio) {
               X += -dir.x/dir.y;
               Y += -dir.z/(dir.y);
           }
           else if (abs(dir.x)<abs(dir.z)) {
               X += dir.x/abs(dir.z)*ratio * -sign(dir.z);
               Y += dir.y/abs(dir.z);
           }
           else {
               X += dir.z/abs(dir.x)*ratio * -sign(dir.x);
               Y += dir.y/abs(dir.x);
           }
           dir = vec3(X, Y, 1.0)+ vec3(u_ViewTransform[2].xy, 0.0);

//            dir = vec3(-dir.xy/dir.z, 1.0);
//            dir = u_InverseViewTransform * dir;
           return texture2D(u_Tex2, proj2(dir.xy));
       }
        else return sphereMap(dir);
    }
    else {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
}

vec4 backgroundDirect(vec3 dir, vec2 outPos) {
    if (u_Tex2Transform[2][2]!=0.0) {
        if (u_BackgroundMode==1) return planeMap(dir);
        else if (u_BackgroundMode==2) return boxMap(dir);
        else if (u_BackgroundMode==3) return texture2D(u_Tex2, proj2(outPos));
        else return sphereMap(dir);
    }
    else {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
}


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

vec3 getNormal(vec2 p, bool heightMap, float intensity) {
    float deltaX = 0.0005;
    float dzdx, dzdy;
    if (!heightMap)
        dzdx = (height(intensity, texture2D(u_Tex0, proj0(vec2(p.x+deltaX, p.y))))
           - height(intensity, texture2D(u_Tex0, proj0(vec2(p.x-deltaX, p.y)))));
    else
        dzdx = (height(intensity, texture2D(u_Tex1, proj1(vec2(p.x+deltaX, p.y))))
           - height(intensity, texture2D(u_Tex1, proj1(vec2(p.x-deltaX, p.y)))));
    
    float deltaY = 0.0005;
    if (!heightMap)
        dzdy = (height(intensity, texture2D(u_Tex0, proj0(vec2(p.x, p.y+deltaY))))
           - height(intensity, texture2D(u_Tex0, proj0(vec2(p.x, p.y-deltaY)))));
    else
        dzdy = (height(intensity, texture2D(u_Tex1, proj1(vec2(p.x, p.y+deltaY))))
           - height(intensity, texture2D(u_Tex1, proj1(vec2(p.x, p.y-deltaY)))));
    
    //vec3 unormal = vec3(-2.0*deltaY*dzdx, -2.0*deltaX*dzdy, deltaX*deltaY);
    vec3 unormal = vec3(0.5*dzdx/deltaX, 0.5*dzdy/deltaY, 1.0);
    return (unormal.x==0.0 && unormal.y==0.0 && unormal.z==0.0) ? vec3(0.0, 0.0, 1.0) : normalize(unormal);
}

float distSegSeg(vec3 S1P0, vec3 S1P1, vec3 S2P0, vec3 S2P1) {
    vec3 u = S1P1 - S1P0;
    vec3 v = S2P1 - S2P0;
    vec3 w = S1P0 - S2P0;
    float a = dot(u,u);         // always >= 0
    float b = dot(u,v);
    float c = dot(v,v);         // always >= 0
    float d = dot(u,w);
    float e = dot(v,w);
    float D = a*c - b*b;        // always >= 0
    float sc, sN, sD = D;       // sc = sN / sD, default sD = D >= 0
    float tc, tN, tD = D;       // tc = tN / tD, default tD = D >= 0

    // compute the line parameters of the two closest points
    if (D < SMALL_NUM) { // the lines are almost parallel
        sN = 0.0;         // force using point P0 on segment S1
        sD = 1.0;         // to prevent possible division by 0.0 later
        tN = e;
        tD = c;
    }
    else {                 // get the closest points on the infinite lines
        sN = (b*e - c*d);
        tN = (a*e - b*d);
        if (sN < 0.0) {        // sc < 0 => the s=0 edge is visible
            sN = 0.0;
            tN = e;
            tD = c;
        }
        else if (sN > sD) {  // sc > 1  => the s=1 edge is visible
            sN = sD;
            tN = e + b;
            tD = c;
        }
    }

    if (tN < 0.0) {            // tc < 0 => the t=0 edge is visible
        tN = 0.0;
        // recompute sc for this edge
        if (-d < 0.0)
            sN = 0.0;
        else if (-d > a)
            sN = sD;
        else {
            sN = -d;
            sD = a;
        }
    }
    else if (tN > tD) {      // tc > 1  => the t=1 edge is visible
        tN = tD;
        // recompute sc for this edge
        if ((-d + b) < 0.0)
            sN = 0.0;
        else if ((-d + b) > a)
            sN = sD;
        else {
            sN = (-d +  b);
            sD = a;
        }
    }
    // finally do the division to get sc and tc
    sc = (abs(sN) < SMALL_NUM ? 0.0 : sN / sD);
    tc = (abs(tN) < SMALL_NUM ? 0.0 : tN / tD);

    // get the difference of the two closest points
    vec3 dP = w + (sc * u) - (tc * v);  // =  S1(sc) - S2(tc)

    return length(dP);   // return the closest distance
}

mat3 trianglesIntersection2(vec2 p, float step, vec3 origin, vec3 dir, float intensity, bool heightMap) {
    // compute height and color
    vec2 s = vec2(step, 0.0);
    vec2 p11 = p+s.xx;

    vec4 c00 = heightMap ? texture2D(u_Tex1, proj1(p)): texture2D(u_Tex0, proj0(p));
    float h00 = height(intensity, c00);
    vec3 A = vec3(p, h00);

    vec4 c10 = heightMap ? texture2D(u_Tex1, proj1(p+s)): texture2D(u_Tex0, proj0(p+s));
    float h10 = height(intensity, c10);
    vec3 B = vec3(p+s, h10);

    vec4 c01 = heightMap ? texture2D(u_Tex1, proj1(p+s.yx)): texture2D(u_Tex0, proj0(p+s.yx));
    float h01 = height(intensity, c01);
    vec3 C = vec3(p+s.yx, h01);

    vec4 c11 = heightMap ? texture2D(u_Tex1, proj1(p11)): texture2D(u_Tex0, proj0(p11));
    float h11 = height(intensity, c11);
    vec3 D = vec3(p11, h11);

    vec3 inf = origin + 1e6 * dir;
    float frameDist = u_Thickness==0.0 ? 1e9 : min(
        min(distSegSeg(origin, inf, A, B), distSegSeg(origin, inf, C, D)),
        min(distSegSeg(origin, inf, A, C), distSegSeg(origin, inf, B, D)) );

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
//            normal = normalize(cross(vec3(step, 0.0, h10-h00), vec3(0.0, step, h01-h00)));
            normal = normalize(mix(normalize(cross(vec3(step, 0.0, h10-h00), vec3(0.0, step, h01-h00))), normalize(cross(vec3(-step, 0.0, h01-h11), vec3(0.0, -step, h10-h11))), 0.5));
            if (u_NormalSmoothing!=0.0) normal = mix(normal, getNormal(intersection.xy, heightMap, intensity), u_NormalSmoothing*0.01);
            return mat3(intersection, normal, vec3(frameDist, 0.0, 0.0));
        }
    }
    if (k2>0.0) {
        intersection = origin + k2*dir;
        vec2 relInt = intersection.xy-p.xy;
        if (relInt.x>=0.0 && relInt.x<=step && relInt.y>=0.0 && relInt.y<=step
        && step-relInt.x<=relInt.y) {
//            normal = normalize(cross(vec3(-step, 0.0, h01-h11), vec3(0.0, -step, h10-h11)));
            normal = normalize(mix(normalize(cross(vec3(step, 0.0, h10-h00), vec3(0.0, step, h01-h00))), normalize(cross(vec3(-step, 0.0, h01-h11), vec3(0.0, -step, h10-h11))), 0.5));
            if (u_NormalSmoothing!=0.0) normal = mix(normal, getNormal(intersection.xy, heightMap, intensity), u_NormalSmoothing*0.01);
            return mat3(intersection, normal, vec3(frameDist, 0.0, 0.0));
        }
    }


    return mat3(vec3(OOB, OOB, OOB), vec3(0.0, 0.0, 0.0), vec3(frameDist, 0.0, 0.0));
}


vec4 bkdDebug(vec2 pos, vec2 outPos) {
    float intensity = getMaskedParameter(u_Intensity, outPos);
    vec4 backgroundColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;
    dir = mat3(u_Model3DTransform) * dir;
    return texture2D(u_Tex0, proj0(-dir.xy/dir.z));
//    return texture2D(u_Tex0, -dir.xy/dir.z);//planeMap(dir);
}

vec4 triangles(vec2 pos, vec2 outPos) {
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

    if (k1>k2) /*return background(dir);//*/backgroundDirect(dir, outPos);
//    if (k1>k2) return backgroundColor;

    float k = k1;
    vec3 p = cameraPos + k*dir;

    vec4 color = /*background(dir);//*/backgroundDirect(dir, outPos); //backgroundColor;
    float h = 0.0;
    float dz = 0.0;
    float prevDz;
    vec4 prevColor;
    float prevH;
    bool stop;

    float strideX = sign(dir.x) * squareSize;
    float strideY = sign(dir.y) * squareSize;

    float intersected = 0.0;

    vec4 outColor = vec4(0.0, 0.0, 0.0, 0.0);//color; //backgroundColor;
    vec2 nextLines = sign(dir.xy)*squareSize/2.0; //vec2(sign(dir.x)*squareSize, sign(dir.y)*squareSize)/2.0;
int maxIter = 1000;
    float frameDist = 1e10;

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

        if (abs(squareCenter.x)<surfaceWidth/2.0 && abs(squareCenter.y)<surfaceHeight/2.0) {
            vec2 bottomLeft = squareCenter - vec2(squareSize, squareSize)/2.0;

            // compute triangles intersection
            mat3 intersection = trianglesIntersection2(bottomLeft, squareSize, p, dir, intensity, heightMap);

            frameDist = min(intersection[2].x, frameDist);

            if (intersection[0][0]!=OOB /*&& indexY>0.0 && indexY<u_Resolution*/) {
//                vec4 col = u_ColorScheme==0.0 ? texture2D(u_Tex0, proj0(squareCenter.xy))
//                        : u_ColorScheme==100.0 ? texture2D(u_Tex0, proj0(intersection[0].xy))
//                        : mix(texture2D(u_Tex0, proj0(squareCenter.xy)), texture2D(u_Tex0, proj0(intersection[0].xy)), u_ColorScheme*0.01);
                vec4 col = texture2D(u_Tex0, proj0(squareCenter.xy))*0.5 + texture2D(u_Tex0, proj0(intersection[0].xy))*0.5;


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
                    vec4 reflected = backgroundForReflection(reflectDir);//getBackground(backPos);

                    float lum = (reflected.r+reflected.g+reflected.b)*0.3333333;
                    float k = min(1.0, lum*u_Reflectivity*0.1);
//                    sampled = mix(u_Color2, reflected, k);
                    sampled = mix(sampled, reflected, k); //u_Reflectivity*0.01);
                }

                outColor =  intersected==0.0 ? sampled : vec4(mix(outColor.rgb, sampled.rgb, intersected/(intersected+sampled.a)), outColor.a+(1.0-outColor.a)*sampled.a);
                intersected += sampled.a;
    //                intersected = 1.0; // break condition
    //                vec4 sampled = texture2D(u_Tex0, proj0(squareCenter.xy));
    //                outColor = intersected==0.0 ? sampled : mix(outColor, sampled, 0.05/(intersected+0.2));
    //                intersected += 0.2; // break condition

            }
        }
//        if (abs(squareCenter.z-p.z)<squareSize) {
//        if (squareCenter.z > p.z) {
//            outColor = texture2D(u_Tex0, proj0(squareCenter.xy));
//            intersected = 1.0; // break condition
//        }

        // advance
        vec2 next = squareCenter.xy + nextLines;
        vec2 deltaK = (next-p.xy)/dir.xy;
        float minK = min(deltaK.x, deltaK.y); //if (minK<0.0001) minK = max(deltaK.x, deltaK.y);
        k += minK;
        p += minK*dir;
        --maxIter;
    }
//if (maxIter<=0) return vec4(0.0, 0.0, 1.0, 1.0);

    outColor = mix(color, vec4(outColor.rgb, color.a), outColor.a);

    //frame
    vec4 frameColor = vec4(mix(outColor.rgb, u_Color1.rgb, u_Color1.a), 1.0);
    float frameK = u_Thickness==0.0 ? 0.0 : smoothstep(0.0, 1.0, smoothstep(0.0002*u_Thickness, 0.0, frameDist) + 0.4*(u_Glow==0.0 ? 0.0 : smoothstep(0.002*u_Glow, 0.0, frameDist)));
    outColor = mix(outColor, frameColor, frameK);

    return outColor;
//    return mix(mix(vec4(length(cross(dir, vec3(0.0, 0.0, 1.0))), 1.0-length(cross(dir, vec3(0.0, 0.0, 1.0))), 0.0, 1.0), getBackground(pos), 0.5), wireColor, intersected);
}

#include mainWithOutPos(triangles)
