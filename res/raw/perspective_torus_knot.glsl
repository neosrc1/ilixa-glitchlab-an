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

float sqr(float x) { return x*x; }

float implicitFn0(vec3 p) {
    float R = 0.5;
    float r = R*u_Radius*0.02;
    float a = sqrt(p.x*p.x + p.y*p.y) - R;
    vec2 q = vec2(a, p.z);
    float ang = atan(p.y, p.x)*0.5*(u_Count-1.0);
    float ca = cos(ang);
    float sa = sin(ang);
    mat2 rot = mat2(ca, sa, sa, -ca);
    vec2 c1 = rot*vec2(-0.15, 0.);
    vec2 c2 = rot*vec2(0.15, 0.);
    return 0.4*min(length(q-c1) - r, length(q-c2) - r);
}

float implicitFn(vec3 p) {
    float R = 0.5;
    float r = R*u_Radius*0.02;
    float a = sqrt(p.x*p.x + p.y*p.y) - R;
    float ang = atan(p.y, p.x)*0.5*(u_Count-1.0);
    float ca = cos(ang);
    float sa = sin(ang);
    mat2 rot = mat2(ca, sa, sa, -ca);
    vec2 q = rot * vec2(a, p.z);
    if (q.x<0.0) q = -q;
    vec2 c1 = vec2(0.15, 0.);
    return 0.4*(length(q-c1) - r);
}

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

vec3 getIntersectionD(vec3 origin, vec3 dir) {
    float minDist = 1e9;
    float k = 0.0;
    if (u_GlowColor.r==0.0 && u_GlowColor.g==0.0 && u_GlowColor.b==0.0) {
        vec2 kBounds = sphereIntersection(vec3(0.0, 0.0, 0.0), 0.5*(1.0+1.25+u_Radius*0.02), origin, dir);
        float k = kBounds.x;
        if (k<0.0) return vec3(k, 0.0, minDist);
    }

    float de = 0.0001;
    int maxIter = 1256;
    int iter = 0;
    vec3 p = origin;
    float dist = implicitFn(p);
    while (abs(dist)>de && iter<maxIter) {
        k += abs(dist);
        p = origin + k*dir;
        dist = implicitFn(p);
        minDist = min(minDist, abs(dist));
        ++iter;
    }
    return dist<de ? vec3(k, iter, minDist) : vec3(-1.0, iter, minDist);
}

vec3 getNormal(vec3 p) {
    float d = 0.0001;
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

    vec4 mixedCol = mix(reflectedColor, col, clamp(0.0, 1.0, incidence + u_Balance*0.01));
    if (objectIntersected) mixedCol = mix(mixedCol, mixedCol*vec4(2.0*u_ObjectColor.rgb, 1.0), u_ObjectColor.a);
    else mixedCol = mix(mixedCol, mixedCol*vec4(2.0*u_BkgColor.rgb, 1.0), u_BkgColor.a);
    vec4 glowCol = mixedCol + vec4(u_GlowColor.rgb*0.1/pow(minDist, 1.0), 0.0)*u_GlowColor.a;
    return glowCol;
}

#include mainWithOutPos(rrS)
