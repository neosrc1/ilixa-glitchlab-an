precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Count;
uniform float u_Intensity;
uniform mat3 u_InverseModelTransform;

vec4 ripples(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = u.y;

    if (d < 0.0) {
        return texture2D(u_Tex0, proj0(pos));
    }

    float radius = 0.5;

    float p = u_Perspective * radius;
    float pd = u_Perspective==0.0 ? 0.0 : u_Perspective >= 10000.0 ? d : (p*d)/(p+d);

    float intensity = getMaskedParameter(u_Intensity, outPos);
    float dilation = intensity * radius*0.005 * sin(pd * M_PI*100.0/radius);
//    float sx = x - sa*dilation;
//    float sy = y + ca*dilation;

    vec2 coord = (u_ModelTransform * vec3(u.x, u.y + dilation, 1.0)).xy;
    return texture2D(u_Tex0, proj0(coord));

}

#include mainWithOutPos(ripples)
