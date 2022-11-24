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

float implicitFn(vec3 p) {
    vec2 t = p.xy;
    vec2 z = vec2(0.0, p.z);
//    vec2 z = p.yz;
//    vec2 t = vec2(p.x+p.z, p.y+p.z);
    vec2 prev = t;

    int iter = 0;
    float d2 = 0.0;
    float d = length(z);
    while (iter < int(u_Count)) {
        ++iter;
        prev = z;
        z.x = prev.x*prev.x - prev.y*prev.y + t.x;
        z.y = 2.0*prev.x*prev.y + t.y;
        d2 = dot(z, z);
        if (d2 > 4.2) {
            return d2-4.0;
        }
    }

    d2 = d*d;
    return d2-4.0;
}

vec2 sphereIntersection2(vec3 center, float radius, vec3 origin, vec3 dir) {
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
float getIntersection(vec3 origin, vec3 dir) {
    float dk = 0.001;
    float de = 0.001;
    float k0 = 0.0;
    float k1 = dk;
    int maxIter = 100;
    int iter = 0;
    while (iter<maxIter) {
        vec3 x0 = origin + k0*dir;
        vec3 x1 = origin + k1*dir;
        float a = implicitFn(x0);
        float b = implicitFn(x1);

        if (abs(a)<de) return k0;
        if (abs(b)<de) return k1;

        float dy = b-a;
        float dk = k1-k0;
        float deriv = dy/dk;

        float k2 = k0 - a/deriv;
        if (k2<k0) return -1.0; // k0 should always be the lowest possible k

        vec3 x2 = origin + k2*dir;
        float c = implicitFn(x2);

        if (sign(a)!=sign(c)) {
            if (sign(a)==sign(b)) k0 = k1;
            k1 = k2;
        }
        else {
            k0 = k1;
            k1 = k2;
        }

        ++iter;
    }
    return (k0+k1)/2.0;
}

vec2 getIntersectionD(vec3 origin, vec3 dir) {
//    vec2 kBounds = sphereIntersection2(vec3(0.0, 0.0, 0.0), 1.0, origin, dir);
    vec2 kBounds = sphereIntersection2(vec3(0.0, 0.0, 0.0), 4.0, origin, dir);
    float k0 = kBounds.x;
    if (k0<0.0) return vec2(k0, 0.0);
    float k1 = k0;

    float originSign = sign(implicitFn(origin));
    float steps = 40.0 + u_Count*40.0;
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
    } while (k1<kBounds.y && sign(b)==originSign);

    if (sign(b)==originSign) return vec2(-1.0, 0.0);

    float de = 0.001;
    int maxIter = 30;
    int iter = 0;
    while (iter<maxIter) {
        float dy = b-a;
        dk = k1-k0;
        float deriv = dy/dk;

        float k2 = k0 - a/deriv;
        if (k2<kBounds.x || k2>kBounds.y) k2 = (k0+k1)/2.0; //return vec2(-1.0, iter);

        vec3 x2 = origin + k2*dir;
        float c = implicitFn(x2);
        if (abs(c)<de) return vec2(k2, iter);

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
    return vec2((k0+k1)/2.0, iter);
}

vec3 getNormal(vec3 p) {
    float d = 0.1;
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
    vec4 reflectedColor;
    float fniter = 0.0;

    do {
        minK = OOB;
        minI = -1;

        //float k = getIntersection(origin, dir);
        vec2 inters = getIntersectionD(origin, dir);
        float k = inters.x;
        fniter = inters.y;
        if (k>0.0 && k<minK) {
            minK = k;
            minI = 0;
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
    vec4 iterCol;
    if (iter==maxIter) iterCol = vec4(1.0, 1.0, 1.0, 1.0);
    else if (iter==maxIter-1) iterCol = vec4(1.0, 0.0, 0.0, 1.0);
    else if (iter==maxIter-2) iterCol = vec4(0.0, 1.0, 0.0, 1.0);
    else if (iter==maxIter-3) iterCol = vec4(0.0, 0.0, 1.0, 1.0);
    else iterCol = vec4(0.0, 0.0, 0.0, 1.0);

    vec4 mixedCol = mix(reflectedColor, col, clamp(0.0, 1.0, incidence + u_Balance*0.01));
    return mix(mixedCol, vec4(fniter/5.0, fniter==0.0 ? 1.0 : 0.0, fniter>=100.0 ? 1.0 :0.0, 1.0), 0.0);
//    return col;
//    return mix(col, iterCol, 0.25);//vec4(col.r, col.g, col.b*clamp(0.0, 1.0, float(iter+2)/4.0), col.a);
}

#include mainWithOutPos(rrS)
