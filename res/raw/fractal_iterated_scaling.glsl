precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform vec4 u_Color1;
uniform float u_Thickness;
uniform float u_Count;


vec4 iterscale(vec2 pos, vec2 outPos) {
    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    vec2 u = pos / vec2(ratio, 1.0);
    u = vec2(fmod(u.x+1.0, 2.0), fmod(u.y+1.0, 2.0))-vec2(1.0, 1.0);

    float len = 3.0-pow(0.5, u_Count-1.0)*2.0;
    u *= len;

    vec2 indexes = floor(-log(3.0-abs(u))/log(2.0));
    float index = max(indexes.x, indexes.y);

    vec2 s = sign(u);
    u = abs(u);

    float offset = pow(0.5, index);
    u = vec2(2.0, 2.0) - vec2(offset, offset) - u;
    u = vec2(1.0, 1.0) - u;
    u = vec2(fmod(u.x, 1.0), fmod(u.y, 1.0));
    if (index==-2.0) u *= s;
    else u =u*pow(2.0, index+2.0)*s-1.0;
    u *= vec2(ratio, 1.0);

    return texture2D(u_Tex0, proj0(u));

}

#include mainWithOutPos(iterscale)