precision highp float;
precision highp int;
#define OOB 999999.99

#include math
#include commonvar
#include commonfun
#include bkg3d

uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;
uniform float u_Count;
uniform float u_Intensity;
uniform float u_Balance;
uniform float u_Radius;
uniform vec4 u_ObjectColor;
uniform vec4 u_GlowColor;
uniform vec4 u_BkgColor;

uniform vec4 u_Spheres[32];
uniform int u_SphereCount;

float implicitFn(vec3 p) {
    float total = 0.0;
    for(int i=0; i<u_SphereCount; ++i) {
        total += 1.0/length(u_Spheres[i].xyz-p) - 1.0/u_Spheres[i].a;
    }
    return total;
}

//float sphereIntersection(vec3 center, float radius, vec3 origin, vec3 dir) {
//    vec3 relOrigin = origin-center;
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
//            return l;//center+origin + l*dir;
//        }
//    }
//    return -1.0;
//}

vec2 sphereIntersection(vec3 center, float radius, vec3 origin, vec3 dir) {
    vec3 relOrigin = origin-center;
    float a = dot(dir, dir);
    float b = 2.0*dot(dir, relOrigin);
    float c = dot(relOrigin, relOrigin) - radius*radius;
    float delta = b*b - 4.0*a*c; //147
    if (delta>=0.0) {
        float sqrtDelta = sqrt(delta);
        float l1 = (-b - sqrtDelta) / (2.0*a);
        float l2 = (-b + sqrtDelta) / (2.0*a);
        float l = l1>0.0 ? l1 : (l2>0.0 ? l2 : -1.0);
        if (l>0.0) {
            return vec2(max(0.0, l1), l2);
        }
    }
    return vec2(-1.0, -1.0);
}

// negative inside, positive outside
//float getIntersection(vec3 origin, vec3 dir) {
//    float dk = 0.001;
//    float de = 0.001;
//    float k0 = 0.0;
//    float k1 = dk;
//    int maxIter = 100;
//    int iter = 0;
//    while (iter<maxIter) {
//        vec3 x0 = origin + k0*dir;
//        vec3 x1 = origin + k1*dir;
//        float a = implicitFn(x0);
//        float b = implicitFn(x1);
//
//        if (abs(a)<de) return k0;
//        if (abs(b)<de) return k1;
//
//        float dy = b-a;
//        float dk = k1-k0;
//        float deriv = dy/dk;
//
//        float k2 = k0 - a/deriv;
//        if (k2<k0) return -1.0; // k0 should always be the lowest possible k
//
//        vec3 x2 = origin + k2*dir;
//        float c = implicitFn(x2);
//
//        if (sign(a)!=sign(c)) {
//            if (sign(a)==sign(b)) k0 = k1;
//            k1 = k2;
//        }
//        else {
//            k0 = k1;
//            k1 = k2;
//        }
//
//        ++iter;
//    }
//    return (k0+k1)/2.0;
//}
vec3 getIntersectionD(vec3 origin, vec3 dir) {
    float minDist = 1e9;
    float k0 = 0.0;
    float sphereRad = (u_GlowColor.r==0.0 && u_GlowColor.g==0.0 && u_GlowColor.b==0.0) ? 2.5 : 5.0;
    vec2 kBounds = sphereIntersection(vec3(0.0, 0.0, 0.0), sphereRad, origin, dir);
    k0 = kBounds.x;
    if (k0<0.0) return vec3(k0, 0.0, minDist);
    float k1 = k0;

    float originSign = sign(implicitFn(origin));
    float steps = 100.0;
    float dk = (kBounds.y-kBounds.x)/steps;
    vec3 x0 = origin + k0*dir;
    vec3 x1 = x0;
    float a = implicitFn(x0);
    float b = a;

    do {
        k0 = k1;
        x0 = x1;
        a = b;
        k1 += dk;
        x1 = origin + k1*dir;
        b = implicitFn(x1);
        minDist = min(minDist, abs(b));
    } while (k1<kBounds.y && sign(b)==originSign);

    if (sign(b)==originSign) return vec3(-1.0, 0.0, minDist);

    float de = 0.001;
    int maxIter = 100;
    int iter = 0;
    while (iter<maxIter) {
        float dy = b-a;
        dk = k1-k0;
        float deriv = dy/dk;

        float k2 = k0 - a/deriv;
        if (k2<kBounds.x || k2>kBounds.y) k2 = (k0+k1)/2.0; //return vec2(-1.0, iter);

        vec3 x2 = origin + k2*dir;
        float c = implicitFn(x2);
        minDist = min(minDist, abs(c));
        if (abs(c)<de) return vec3(k2, iter, minDist);

        if (sign(a)!=sign(c)) {
            k1 = k2;
            b = c;
        }
        else {
            k0 = k2;
            a = c;
        }

        ++iter;
    }
    return vec3((k0+k1)/2.0, iter, minDist);
}
//    float dk = 0.001;
//    float de = 0.001;
//    //float k0 = 0.0;
//    float k1 = dk;
//    int maxIter = 100;
//    int iter = 0;
//    while (iter<maxIter) {
//        vec3 x0 = origin + k0*dir;
//        vec3 x1 = origin + k1*dir;
//        float a = implicitFn(x0);
//        float b = implicitFn(x1);
//
//        if (abs(a)<de) return vec2(k0, iter);
//        if (abs(b)<de) return vec2(k1, iter);
//
//        float dy = b-a;
//        float dk = k1-k0;
//        float deriv = dy/dk;
//
//        float k2 = k0 - a/deriv;
//        if (k2<0.0) return vec2(-1.0, iter); // k0 should always be the lowest possible k
//
//        vec3 x2 = origin + k2*dir;
//        float c = implicitFn(x2);
//
//        if (sign(a)!=sign(c)) {
//            if (sign(a)==sign(b)) k0 = k1;
//            k1 = k2;
//        }
//        else {
//            k0 = k1;
//            k1 = k2;
//        }
//
//        ++iter;
//    }
//    return vec2((k0+k1)/2.0, iter);
//}

//vec3 getIntersectionD(vec3 origin, vec3 dir) {
//    float minDist = 1e9;
//    float k = 0.0;
//    if (u_GlowColor.r==0.0 && u_GlowColor.g==0.0 && u_GlowColor.b==0.0) {
//        vec2 kBounds = sphereIntersection(vec3(0.0, 0.0, 0.0), 2.2, origin, dir);
//        float k = kBounds.x;
//        if (k<0.0) return vec3(k, 0.0, minDist);
//    }
//
//    float de = 0.0001;
//    int maxIter = 1256;
//    int iter = 0;
//    vec3 p = origin;
//    float dist = implicitFn(p);
//    while (abs(dist)>de && iter<maxIter) {
//        k += abs(dist);
//        p = origin + k*dir;
//        dist = implicitFn(p);
//        minDist = min(minDist, abs(dist));
//        ++iter;
//    }
//    return dist<de ? vec3(k, iter, minDist) : vec3(-1.0, iter, minDist);
//}

vec3 getNormal(vec3 p) {
    float d = 0.01;
    float d2 = d*2.0;
    return normalize(vec3(
        (implicitFn(vec3(p.x-d, p.y, p.z))-implicitFn(vec3(p.x+d, p.y, p.z)))/d2,
        (implicitFn(vec3(p.x, p.y-d, p.z))-implicitFn(vec3(p.x, p.y+d, p.z)))/d2,
        (implicitFn(vec3(p.x, p.y, p.z-d))-implicitFn(vec3(p.x, p.y, p.z+d)))/d2
        ));
}

vec4 rrS(vec2 pos, vec2 outPos) {
    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;

    float eta = u_Intensity*0.01;

    vec3 origin = cameraPos;
    int maxIter = 12;
    int iter = maxIter;
    int minI = -1;
    float minK = OOB;
    float incidence = 2.0;
    vec4 reflectedColor = vec4(0.0, 0.0, 0.0, 1.0);
    float fniter = 0.0;
    float minDist = 1e9;
    bool objectIntersected = false;

    do {
        minK = OOB;
        minI = -1;

        //float k = getIntersection(origin, dir);
        vec3 inters = getIntersectionD(origin, dir);
        float k = inters.x;
        fniter = inters.y;
        if (k>0.0 && k<minK) {
            minK = k;
            minI = 0;
            objectIntersected = true;
        }
        else if (iter==maxIter) {
            minDist = min(minDist, inters.z);
        }

        if (minI >= 0) {
            vec3 intersection = origin + minK*dir;
            vec3 normal = implicitFn(origin)<=0.0 ? getNormal(intersection) : -getNormal(intersection);
            if (iter==maxIter) {
                incidence = abs(dot(normal, dir));
                vec3 reflectedDir = reflect(dir, normal);
                reflectedColor = background(reflectedDir);
            }
            dir = refract(dir, normal, eta);
            origin = intersection + dir*0.001;
        }

        --iter;
    } while (minI>=0 && iter>0);

    vec4 col = background(dir);
//    vec4 iterCol;
//    if (iter==maxIter) iterCol = vec4(1.0, 1.0, 1.0, 1.0);
//    else if (iter==maxIter-1) iterCol = vec4(1.0, 0.0, 0.0, 1.0);
//    else if (iter==maxIter-2) iterCol = vec4(0.0, 1.0, 0.0, 1.0);
//    else if (iter==maxIter-3) iterCol = vec4(0.0, 0.0, 1.0, 1.0);
//    else iterCol = vec4(0.0, 0.0, 0.0, 1.0);

    vec4 mixedCol = mix(reflectedColor, col, clamp(0.0, 1.0, incidence + u_Balance*0.01));
    if (objectIntersected) mixedCol = mix(mixedCol, mixedCol*vec4(2.0*u_ObjectColor.rgb, 1.0), u_ObjectColor.a);
    else mixedCol = mix(mixedCol, mixedCol*vec4(2.0*u_BkgColor.rgb, 1.0), u_BkgColor.a);
//    float glowIntensity = mix(3.0/pow(minDist, 1.0), 1.0/pow(minDist, 5.0), clamp(0.0, 1.0, minDist/2.5));
    float glowIntensity = 1.4/pow(minDist, clamp(1.0, 3.0, minDist));
    vec4 glowCol = mixedCol + vec4(u_GlowColor.rgb*glowIntensity, 0.0)*u_GlowColor.a;
    return mix(glowCol, vec4(fniter/5.0, fniter==0.0 ? 1.0 : 0.0, fniter>=100.0 ? 1.0 :0.0, 1.0), 0.0);
}

#include mainWithOutPos(rrS)
