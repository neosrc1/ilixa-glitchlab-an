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
uniform vec4 u_ObjectColor;
uniform vec4 u_GlowColor;
uniform vec4 u_BkgColor;

uniform vec4 u_Spheres[32];
uniform int u_SphereCount;

float sphereIntersection(vec3 center, float radius, vec3 origin, vec3 dir) {
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
            return l;//center+origin + l*dir;
        }
    }
    return -1.0;
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
    float minDist = 1e9;

    do {
        minK = OOB;
        minI = -1;
        for(int i=0; i<u_SphereCount; ++i) {
            float k = sphereIntersection(u_Spheres[i].xyz, u_Spheres[i].a, origin, dir);
            if (k>0.0 && k<minK) {
                minK = k;
                minI = i;
            }
            else {
                minDist = min(minDist, abs(length(cross(dir, cameraPos-u_Spheres[i].xyz))/length(dir) - u_Spheres[i].a));
            }
        }
        if (minI >= 0) {
            vec3 center = u_Spheres[minI].xyz;
            vec3 intersection = origin + minK*dir;
            vec3 relInt = intersection-center;
            vec3 normal = length(origin-center)<=u_Spheres[minI].a ? -normalize(relInt) : normalize(relInt);
            if (iter==maxIter) {
                incidence = abs(dot(normal, dir));
                vec3 reflectedDir = reflect(dir, normal);
                reflectedColor = background(reflectedDir)*mix(vec4(1.0, 1.0, 1.0, 1.0), vec4(2.0*u_ObjectColor.rgb, 1.0), u_ObjectColor.a);
            }
            dir = refract(dir, normal, eta);
            origin = intersection + dir*0.001;
        }

        --iter;
    } while (minI>=0 && iter>0);

    vec4 col = background(dir)*mix(vec4(1.0, 1.0, 1.0, 1.0), vec4(2.0*u_BkgColor.rgb, 1.0), u_BkgColor.a) + vec4(u_GlowColor.rgb*0.2/pow(minDist, 1.5), 0.0)*u_GlowColor.a;
    vec4 iterCol;
    if (iter==maxIter) iterCol = vec4(1.0, 1.0, 1.0, 1.0);
    else if (iter==maxIter-1) iterCol = vec4(1.0, 0.0, 0.0, 1.0);
    else if (iter==maxIter-2) iterCol = vec4(0.0, 1.0, 0.0, 1.0);
    else if (iter==maxIter-3) iterCol = vec4(0.0, 0.0, 1.0, 1.0);
    else iterCol = vec4(0.0, 0.0, 0.0, 1.0);

    return mix(reflectedColor, col, clamp(0.0, 1.0, incidence + u_Balance*0.01));
//    return col;
//    return mix(col, iterCol, 0.25);//vec4(col.r, col.g, col.b*clamp(0.0, 1.0, float(iter+2)/4.0), col.a);
}

#include mainWithOutPos(rrS)
