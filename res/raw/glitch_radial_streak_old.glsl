precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include color

uniform float u_Phase;
uniform float u_LightAngle;
uniform float u_Thickness;
uniform mat3 u_InverseModelTransform;

vec4 rainbow(vec2 pos, vec2 outPos) {

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    float d = length(u);
    float thickn = 0.01*u_Thickness;
    if (d<1.0-thickn || d>1.0) return texture2D(u_Tex0, proj0(pos));

    if (u_LightAngle <= M_2PI) {
        float da = 0.0;
        if (d > 0.0) {
            float ang = acos(u.x/d);
            if (u.y < 0.0) ang = M_2PI - ang;

            ang += u_Phase + M_PI/2.0 + u_LightAngle/2.0;
            ang = fmod(ang + M_2PI, M_2PI);
            if (ang > u_LightAngle) {
//            return vec4(0.0, 1.0, 1.0, 1.0);
                float newAng = (ang-u_LightAngle) * M_2PI/(M_2PI-u_LightAngle);
                newAng = u_Phase - newAng;// - u_LightAngle/2.0;
                vec2 pos2 = (u_InverseModelTransform * vec3(-d*sin(newAng), -d*cos(newAng), 1.0)).xy;
                return texture2D(u_Tex0, proj0(pos2));
            }
            else {
                vec2 pos2 = (u_InverseModelTransform * vec3(-d*sin(u_Phase), -d*cos(u_Phase), 1.0)).xy;
                return texture2D(u_Tex0, proj0(pos2));
            }
        }

    }

    return texture2D(u_Tex0, proj0(pos));


}

#include mainWithOutPos(rainbow)
