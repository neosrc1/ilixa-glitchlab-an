precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include color

uniform float u_Phase;
uniform float u_Count;
//uniform float u_Length;
uniform float u_Thickness;
uniform mat3 u_InverseModelTransform;

vec4 radial(vec2 pos, vec2 outPos) {

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    float d = length(u);
    float thickn = 0.01*u_Thickness;
    if (d<1.0-thickn || d>1.0) return texture2D(u_Tex0, proj0(pos));

    float ha = u_Phase/2.0;
    if (u_Phase <= M_2PI) {
        float da = 0.0;
        if (d > 0.0) {
            float ang = acos(u.x/d);
            if (u.y < 0.0) ang = M_2PI - ang;

            ang += /*u_Phase +*/ M_PI/2.0 + ha;
            ang = fmod(ang + M_2PI, M_2PI);
            if (ang <= u_Phase) {
                ang = u_Phase-ang;
                float angleRange = u_Phase/u_Count;
                float index = floor(ang/u_Phase*u_Count);
                float ang1 = /*u_Phase*/-ha + angleRange*index;
                float ang2 = /*u_Phase*/-ha + angleRange*(index+1.0);
                vec2 pos1 = (u_InverseModelTransform * vec3(-d*sin(ang1), -d*cos(ang1), 1.0)).xy;
                vec4 col1 = texture2D(u_Tex0, proj0(pos1));
                vec2 pos2 = (u_InverseModelTransform * vec3(-d*sin(ang2), -d*cos(ang2), 1.0)).xy;
                vec4 col2 = texture2D(u_Tex0, proj0(pos2));

                return mix(col1, col2, 1.0-(ang-angleRange*index)/angleRange);
            }
        }

    }

    return texture2D(u_Tex0, proj0(pos));

}

#include mainWithOutPos(radial)
