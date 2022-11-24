precision highp float;
precision highp int;
#define OOB 999999.99

#include math
#include commonvar
#include commonfun

uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;
uniform float u_Count;
uniform float u_Intensity;
uniform float u_Balance;


vec4 background(vec3 dir) {
    vec3 n = normalize(dir);
    float alpha = getVecAngle(n.xz);
    float beta = asin(n.y);
    float ratio = (u_Tex0Dim.x/u_Tex0Dim.y);
    float nX = 2.0;
    float nY = 1.0;
    return texture2D(u_Tex0, vec2(-alpha/M_PI*0.5*nX, 0.5+nY*beta/M_PI));
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

vec4 rrS(vec2 pos, vec2 outPos) {
    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;

    vec3 intersection = sphereIntersection(vec3(0.0, 0.0, 0.0), 0.5, cameraPos, dir);
    if (intersection.x!=OOB) {
        vec3 normal = normalize(intersection);
        float eta = u_Intensity*0.01;
        float incidence = abs(dot(normal, dir));
        vec3 refractedDir = refract(dir, normal, eta);
        vec3 reflectedDir = reflect(dir, normal);
        vec4 reflectedColor = background(reflectedDir);
        return mix(reflectedColor, background(refractedDir), clamp(0.0, 1.0, incidence + u_Balance*0.01));
    }

    return background(dir);
}

#include mainWithOutPos(rrS)
