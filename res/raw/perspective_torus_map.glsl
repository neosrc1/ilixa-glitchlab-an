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
uniform vec4 u_Color;
uniform float u_Blend;


float sqr(float x) { return x*x; }

float implicitFn(vec3 p) {
    float R = 0.5;
    float r = R*u_Radius*0.02;
    float a = sqrt(p.x*p.x + p.y*p.y) - R;
    return sqrt(a*a + p.z*p.z) - r;
}

float implicitFnSquare(vec3 p) {
    float R = 0.5;
    float r = R*u_Radius*0.02;
    float a = sqrt(p.x*p.x + p.y*p.y) - R;
    //return pow(pow(abs(a), 20.0) + pow(abs(p.z), 20.0), 0.05) - r;
    return max(abs(a), abs(p.z)) -r;
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
    vec2 kBounds = sphereIntersection(vec3(0.0, 0.0, 0.0), 0.5*(1.0+u_Radius*0.02), origin, dir);
    float kk = kBounds.x;
    if (kk<0.0) return vec3(kk, 0.0, minDist);

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

float getFog(float dist, float alpha) {
    return max((dist-0.5)*4.0, 0.0) * u_Color.a;
}


vec4 rrS(vec2 pos, vec2 outPos) {
    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;

    float eta = u_Intensity*0.01;

    vec3 origin = cameraPos;
    vec3 inters = getIntersectionD(origin, dir);

    float k = inters.x;

    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    float blend = u_Blend*0.005;
    float width = ratio*(1.0-blend);
    float height = 1.0-blend;
    float bWidth = width - ratio*blend;
    float bHeight = height - blend;

    if (k>0.0) {

        vec3 intersection = origin + k*dir;

        float R = 0.5;
        float r = R*u_Radius*0.02;
        float x = atan(-intersection.x, -intersection.y) / M_PI * width;
        float a = sqrt(intersection.x*intersection.x + intersection.y*intersection.y) - R;
        float y = atan(a, intersection.z) / M_PI * height;

        vec4 col;
        if (blend == 0.0) col = texture2D(u_Tex0, proj0(vec2(x, y)));
        else col = mix(
            mix(texture2D(u_Tex0, proj0(vec2(x, y))), texture2D(u_Tex0, proj0(vec2(x-sign(x)*(ratio+bWidth), y))), smoothstep(0.0, 2.0*blend*ratio, abs(x)-bWidth)),
            mix(texture2D(u_Tex0, proj0(vec2(x, y-sign(y)*(1.0+bHeight)))), texture2D(u_Tex0, proj0(vec2(x-sign(x)*(ratio+bWidth), y-sign(y)*(1.0+bHeight)))), smoothstep(0.0, 2.0*blend*ratio, abs(x)-bWidth)),
            smoothstep(0.0, 2.0*blend, abs(y)-bHeight)
            );

        float dist = length(origin-intersection);
        float fog = getFog(dist, u_Color.a);
        return vec4(mix(col.rgb, u_Color.rgb, fog), col.a);
    }
    else {
        vec4 col = background(dir);
        float dist = 2.0;
        float fog = clamp(0.0, 1.0, getFog(dist, u_Color.a));
        return vec4(mix(col.rgb, u_Color.rgb, fog), col.a);
    }

}

#include mainWithOutPos(rrS)
