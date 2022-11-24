precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include color

uniform float u_Phase;
uniform float u_Count;
uniform float u_Length;
uniform float u_Thickness;
uniform mat3 u_InverseModelTransform;

//vec4 radial0(vec2 pos, vec2 outPos) {
//    float thickn = 0.01*u_Thickness;
//    float ha = u_Phase/2.0;
//
//    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
//    float d = length(u);
//    if (d<1.0-thickn || d>1.0) return texture2D(u_Tex0, proj0(pos));
//
//    if (u_Phase <= M_2PI) {
//        float da = 0.0;
//        if (d > 0.0) {
//            float ang = acos(u.x/d);
//            if (u.y < 0.0) ang = M_2PI - ang;
//
//            ang += /*u_Phase + */M_PI/2.0 + ha;
//            ang = fmod(ang + M_2PI, M_2PI);
//            if (ang <= u_Phase) {
//                ang = u_Phase-ang;
//                float angleRange = u_Phase/u_Count;
//                float index = floor(ang/u_Phase*u_Count);
//                float ang1 = /*u_Phase*/-ha + angleRange*index;
//                float ang2 = /*u_Phase*/-ha + angleRange*(index+1.0);
//                vec2 pos1 = (u_InverseModelTransform * vec3(-d*sin(ang1), -d*cos(ang1), 1.0)).xy;
//                vec4 col1 = texture2D(u_Tex0, proj0(pos1));
//                vec2 pos2 = (u_InverseModelTransform * vec3(-d*sin(ang2), -d*cos(ang2), 1.0)).xy;
//                vec4 col2 = texture2D(u_Tex0, proj0(pos2));
//
//                return mix(col1, col2, (ang-angleRange*index)/angleRange);
//            }
//        }
//
//    }
//
//    return texture2D(u_Tex0, proj0(pos));
//}

vec4 radial(vec2 pos, vec2 outPos) {
    float thickn = 0.01*u_Thickness;
    float ha = u_Phase/2.0;
    float angleRange = u_Phase/u_Count;

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    if (u_Phase <= M_2PI) {

        float halfThickPos = 1.0-thickn/2.0;

        float phase = 0.0;
        vec2 center = vec2(0.0, 0.0);

        for(int i=0; i<int(ceil(u_Length)); ++i) {
            float d = length(u - center);
            if (d>=1.0-thickn && d<=1.0) {

                float da = 0.0;
                if (d > 0.0) {
                    float ang = acos((u.x-center.x)/d);
                    if (u.y-center.y < 0.0) ang = M_2PI - ang;

                    ang += phase + M_PI/2.0 + ha;
                    ang = fmod(ang + M_2PI, M_2PI);
                    if (ang <= u_Phase) {
                        ang = u_Phase-ang;
                        float index = floor(ang/u_Phase*u_Count);
                        float ang1 = phase -ha + angleRange*index;
                        float ang2 = phase -ha + angleRange*(index+1.0);
                        vec2 pos1 = (u_InverseModelTransform * vec3(center.x-d*sin(ang1), center.y-d*cos(ang1), 1.0)).xy;
                        vec4 col1 = texture2D(u_Tex0, proj0(pos1));
                        vec2 pos2 = (u_InverseModelTransform * vec3(center.x-d*sin(ang2), center.y-d*cos(ang2), 1.0)).xy;
                        vec4 col2 = texture2D(u_Tex0, proj0(pos2));

                        return mix(col1, col2, (ang-angleRange*index)/angleRange);
                    }
                }
            }

            float endAng = phase -ha + ((fmod(float(i), 2.0)==0.0) ? u_Phase : 0.0);
            vec2 posH = vec2(center.x-halfThickPos*sin(endAng), center.y-halfThickPos*cos(endAng));
            center = 2.0*posH - center;
            phase += M_PI;
        }

//        phase = 0.0;
        float endAng = -ha;
        vec2 posH = vec2(-halfThickPos*sin(endAng), -halfThickPos*cos(endAng));
        center = 2.0*posH;
        phase = M_PI;

        for(int i=1; i<int(ceil(u_Length)); ++i) {
            float d = length(u - center);
            if (d>=1.0-thickn && d<=1.0) {

                float da = 0.0;
                if (d > 0.0) {
                    float ang = acos((u.x-center.x)/d);
                    if (u.y-center.y < 0.0) ang = M_2PI - ang;

                    ang += phase + M_PI/2.0 + ha;
                    ang = fmod(ang + M_2PI, M_2PI);
                    if (ang <= u_Phase) {
                        ang = u_Phase-ang;
                        float index = floor(ang/u_Phase*u_Count);
                        float ang1 = phase -ha + angleRange*index;
                        float ang2 = phase -ha + angleRange*(index+1.0);
                        vec2 pos1 = (u_InverseModelTransform * vec3(center.x-d*sin(ang1), center.y-d*cos(ang1), 1.0)).xy;
                        vec4 col1 = texture2D(u_Tex0, proj0(pos1));
                        vec2 pos2 = (u_InverseModelTransform * vec3(center.x-d*sin(ang2), center.y-d*cos(ang2), 1.0)).xy;
                        vec4 col2 = texture2D(u_Tex0, proj0(pos2));

                        return mix(col1, col2, (ang-angleRange*index)/angleRange);
                    }
                }
            }

            float endAng = phase -ha + ((fmod(float(i), 2.0)==1.0) ? u_Phase : 0.0);
            vec2 posH = vec2(center.x-halfThickPos*sin(endAng), center.y-halfThickPos*cos(endAng));
            center = 2.0*posH - center;
//            center += vec2(1.0, 0.0);
            phase += M_PI;
        }

    }

    return texture2D(u_Tex0, proj0(pos));
}

#include mainWithOutPos(radial)
