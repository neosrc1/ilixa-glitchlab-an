precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include locuswithcolor

uniform float u_Dampening;
uniform float u_Power;
uniform mat3 u_ModelTransform1;
uniform mat3 u_ModelTransform2;
uniform mat3 u_ModelTransform3;

vec2 getOffsetPos(mat3 transform, vec2 pos, float k) {
    mat2 tScaleRot = mat2(transform);
    vec2 u = tScaleRot*vec2(1.0, 0.0);
    vec2 v = tScaleRot*vec2(0.0, 1.0);
    vec2 nu = normalize(u);
    vec2 nv = normalize(v);
    vec2 t = vec2(transform[2][0], transform[2][1])*k;
    float tu = dot(nu, t);
    float tv = dot(nv, t);
    float scale = length(u);

    float pu = dot(nu, pos);
    if (pu<=tu-scale || pu>=tu+scale) return pos;
    float k = pow((1.0 + cos((pu-tu)/scale*M_PI))/2.0, pow(1.07, -u_Power));

    return pos - nv * k*tv;
}


vec4 offset(vec2 pos) {
    vec4 col = texture2D(u_Tex0, proj0(pos));
    float k = (u_LocusMode!=6 && u_LocusMode!=7) ? getLocus(pos, vec4(0.0)) : 1.0;

    vec4 red = texture2D(u_Tex0, proj0(getOffsetPos(u_ModelTransform1, pos, k)));
    vec4 green = texture2D(u_Tex0, proj0(getOffsetPos(u_ModelTransform2, pos, k)));
    vec4 blue = texture2D(u_Tex0, proj0(getOffsetPos(u_ModelTransform3, pos, k)));
    vec4 outCol = vec4(red.r, green.g, blue.b, (red.a+green.a+blue.a)/3.0);
    return mix(col, outCol, u_LocusMode>=6 ? getLocus(pos, col, outCol): 1.0);
}

#include mainPerPixel(offset)
