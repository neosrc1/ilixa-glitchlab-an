precision highp float;
precision highp int;
#define OOB 1e9

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
        float eta = getMaskedParameter(u_Intensity, outPos)*0.01;
        float incidence = abs(dot(normal, dir));
        vec3 refractedDir = refract(dir, normal, eta);
        vec3 reflectedDir = reflect(dir, normal);
        vec4 reflectedColor = background(reflectedDir);

        vec3 intersection2 = sphereIntersection(vec3(0.0, 0.0, 0.0), 0.5, intersection+refractedDir*0.00001, refractedDir);
        if (intersection2.x!=OOB) {
            normal = -normalize(intersection2);
            refractedDir = refract(refractedDir, normal, eta);
        }

//        return mix(reflectedColor, background(reflectedDir), u_Balance*0.005 + 0.5);
        vec4 mixedCol = mix(reflectedColor, background(refractedDir), clamp(0.0, 1.0, incidence + u_Balance*0.01));
        mixedCol = mix(mixedCol, mixedCol*vec4(2.0*u_ObjectColor.rgb, 1.0), u_ObjectColor.a);
        return mixedCol;
    }
    else {
        float minDist = abs(length(cross(dir, cameraPos))/length(dir) - 0.5);
        return background(dir)*mix(vec4(1.0, 1.0, 1.0, 1.0), vec4(2.0*u_BkgColor.rgb, 1.0), u_BkgColor.a) + vec4(u_GlowColor.rgb*0.2/pow(minDist, clamp(1.0, 3.0, minDist)), 0.0)*u_GlowColor.a;
//        return background(dir)*vec4(2.0*u_BkgColor.rgb, 1.0) + vec4(u_GlowColor.rgb*0.2/pow(minDist, 1.5), 0.0);
    }
}

#include mainWithOutPos(rrS)
