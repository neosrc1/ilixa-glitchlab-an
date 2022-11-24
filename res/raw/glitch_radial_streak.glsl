precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include color

uniform float u_Count;
uniform float u_Phase;
uniform float u_Intensity;
uniform mat3 u_InverseModelTransform;

//vec4 rainbow(vec2 pos, vec2 outPos) {
//
//    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
//    float d = length(u);
//
//    float angle = u_Intensity*0.01*M_2PI;
//
//    if (angle <= M_2PI) {
//        float da = 0.0;
//        if (d > 0.0) {
//            float ang = acos(u.x/d);
//            if (u.y < 0.0) ang = M_2PI - ang;
//
//            ang += u_Phase + M_PI/2.0 + angle/2.0;
//            ang = fmod(ang + M_2PI, M_2PI);
//            if (ang > angle) {
////            return vec4(0.0, 1.0, 1.0, 1.0);
//                float newAng = (ang-angle) * M_2PI/(M_2PI-angle);
//                newAng = u_Phase - newAng;// - u_LightAngle/2.0;
//                vec2 pos2 = (u_InverseModelTransform * vec3(-d*sin(newAng), -d*cos(newAng), 1.0)).xy;
//                return texture2D(u_Tex0, proj0(pos2));
//            }
//            else {
//                vec2 pos2 = (u_InverseModelTransform * vec3(-d*sin(u_Phase), -d*cos(u_Phase), 1.0)).xy;
//                return texture2D(u_Tex0, proj0(pos2));
//            }
//        }
//
//    }
//
//    return texture2D(u_Tex0, proj0(pos));
//}

vec4 rainbow(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    float d = length(u);

    if (d == 0.0) return texture2D(u_Tex0, proj0(pos));

    float ang = acos(u.x/d);
    if (u.y < 0.0) ang = M_2PI - ang;

    ang -= (u_Phase + M_PI/2.0);

    float sector = M_2PI/u_Count;
    float streakAngle = u_Intensity*0.01*sector;
    float mang = fmod(ang, sector);
    float n = floor(ang/sector);
    float sang;
    if (abs(mang-sector/2.0)>(sector-streakAngle)/2.0) {
        sang = u_Phase + M_PI/2.0 + (mang<=sector/2.0 ? n : n+1.0)*sector;
    }
    else {
        float angleCompression = 1.0 - u_Intensity*0.01;
        sang = u_Phase + M_PI/2.0 + n*sector + sector/2.0 + (mang-sector/2.0)/angleCompression;
    }
    vec2 pos2 = (u_InverseModelTransform * vec3(d*cos(sang), d*sin(sang), 1.0)).xy;
    return texture2D(u_Tex0, proj0(pos2));
}

#include mainWithOutPos(rainbow)
