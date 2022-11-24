precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include locuswithcolor_nodep

uniform float u_Dampening;
uniform mat3 u_ModelTransform1;
uniform mat3 u_ModelTransform2;
uniform mat3 u_ModelTransform3;

vec2 getOffsetPos(mat3 transform, vec2 pos) {
    vec2 tPos = (transform*vec3(pos, 1.0)).xy;
    float dist = length(pos);
    if (dist<1.0) {
        tPos = mix(pos, tPos, 1.0-u_Dampening*0.01*(1.0-dist*dist));
    }
    return tPos;
}

vec4 offset(vec2 pos) {
    vec4 red = texture2D(u_Tex0, proj0(getOffsetPos(u_ModelTransform1, pos)));
    vec4 green = texture2D(u_Tex0, proj0(getOffsetPos(u_ModelTransform2, pos)));
    vec4 blue = texture2D(u_Tex0, proj0(getOffsetPos(u_ModelTransform3, pos)));
    vec4 outColor =  vec4(red.r, green.g, blue.b, (red.a+green.a+blue.a)/3.0);
    vec4 color = texture2D(u_Tex0, proj0(pos));

    float locusIntensity = getLocus(pos, color, outColor);
    return mix(color, outColor, locusIntensity);
}

#include mainPerPixel(offset)
