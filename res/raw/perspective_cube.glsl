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

vec3 fnIntersection(vec3 center, float radius, vec3 origin, vec3 dir) {
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
    vec3 inters = center+origin + k*dir;
//    float err = 0.00001;
//    if (kIn<=0.0 || abs(inters.x-center.x)>radius+err || abs(inters.y-center.y)>radius+err || abs(inters.z-center.z)>radius+err) return vec3(OOB, OOB, OOB);
    return inters;
}

vec3 getNormal(vec3 center, float radius, vec3 intersection) {
    //return normalize(intersection-center);
    vec3 delta = intersection-center;
    vec3 a = abs(delta);
    if (a.x>a.y && a.x>a.z) return vec3(sign(delta.x), 0.0, 0.0);
    else if (a.y>a.z) return vec3(0.0, sign(delta.y), 0.0);
    else return vec3(0.0, 0.0, sign(delta.z));
}

vec4 rrS(vec2 pos, vec2 outPos) {
    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;

    float radius = 0.25;
    vec3 intersection = fnIntersection(vec3(0.0, 0.0, 0.0), radius, cameraPos, dir);
    if (intersection.x!=OOB) {
//        return vec4(1.0, 0.0, 0.0, 1.0);
        vec3 normal = getNormal(vec3(0.0, 0.0, 0.0), radius, intersection);
        float eta = u_Intensity*0.01;
        float incidence = abs(dot(normal, dir));
        vec3 refractedDir = refract(dir, normal, eta);
        vec3 reflectedDir = reflect(dir, normal);
        vec4 reflectedColor = background(reflectedDir);

        vec3 intersection2 = fnIntersection(vec3(0.0, 0.0, 0.0), radius, intersection+refractedDir*0.00001, refractedDir);
        if (intersection2.x!=OOB) {
            normal = -getNormal(vec3(0.0, 0.0, 0.0), radius, intersection2);
            refractedDir = refract(refractedDir, normal, eta);
            //return vec4(1.0, 0.0, 0.0, 1.0);
        }

//        return mix(reflectedColor, background(reflectedDir), u_Balance*0.005 + 0.5);
        vec4 mixedCol = mix(reflectedColor, background(refractedDir), clamp(0.0, 1.0, incidence + u_Balance*0.01));
        mixedCol = mix(mixedCol, mixedCol*vec4(2.0*u_ObjectColor.rgb, 1.0), u_ObjectColor.a);
        return mixedCol;
    }
    else {
        float minDist = abs(length(cross(dir, cameraPos))/length(dir) - radius);
        return background(dir)*mix(vec4(1.0, 1.0, 1.0, 1.0), vec4(2.0*u_BkgColor.rgb, 1.0), u_BkgColor.a) + vec4(u_GlowColor.rgb*0.2/pow(minDist, 1.5), 0.0)*u_GlowColor.a;
        //return background(dir)*vec4(2.0*u_BkgColor.rgb, 1.0) + vec4(u_GlowColor.rgb*0.5/pow(minDist, 2.0), 0.0);
    }
}

#include mainWithOutPos(rrS)
