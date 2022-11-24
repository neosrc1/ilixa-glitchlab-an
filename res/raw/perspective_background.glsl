precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform vec4 u_Color1;
uniform int u_BackgroundMode;
uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;
uniform float u_Count;

vec4 sphereMap(vec3 dir) {
    vec3 n = normalize(dir);
    float alpha = getVecAngle(n.xz);
    float beta = asin(n.y);
    float ratio = (u_Tex0Dim.x/u_Tex0Dim.y);
    float nX = 2.0;
    float nY = 1.0;
    return texture2D(u_Tex0, vec2(-alpha/M_PI*0.5*nX, 0.5+nY*beta/M_PI));
}

vec4 planeMap(vec3 dir) {
    vec2 pos = vec2(-dir.x/dir.z * u_Tex0Dim.y/u_Tex0Dim.x, -dir.y/dir.z)*0.5 + vec2(0.5, 0.5);
    float m = max(abs(pos.x), abs(pos.y));
    float darken = 4.0/max(4.0, m*u_Color1.a*2.0);
//    return texture2D(u_Tex0, pos)*vec4(darken, darken, darken, 1.0);
    return mix(vec4(u_Color1.rgb, 1.0), texture2D(u_Tex0, pos), darken);
}

vec4 boxMap(vec3 dir) {
    float ratio = (u_Tex0Dim.y/u_Tex0Dim.x);
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
    return texture2D(u_Tex0, vec2(X, Y));
}

vec4 background(vec3 dir) {
    if (u_BackgroundMode==1) return planeMap(dir);
    else if (u_BackgroundMode==2) return boxMap(dir);
    else return sphereMap(dir);
}



vec4 bkg(vec2 pos, vec2 outPos) {
    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;

    return background(dir);
}

#include mainWithOutPos(bkg)
