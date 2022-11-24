precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include locuswithcolor_nodep

uniform float u_Shadows;
uniform float u_Length;
uniform mat3 u_InverseModelTransform;

vec4 streak(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    
    float lightness = 1.0;
    vec4 col = texture2D(u_Tex0, proj0(pos));
    vec4 outColor = col;
    if (u.y>0.0) {
        if (abs(u.x)<1.0) {
            float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
            float step = scale*u_Length*0.01;
            u.y = u_Length==0.0? 0.0 : fmod(u.y /*+ step*0.5*/, step);
            vec2 p = (u_InverseModelTransform * vec3(u, 1.0)).xy;
            outColor = texture2D(u_Tex0, proj0(p));
        }
        else if (u_Shadows>0.0) {
            float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
            float dx = (abs(u.x)-1.0) / scale;
            float dy = abs(u.y) / scale;
            float maxDx = 0.25;
            float maxDy = 1.0;
//            if (dy<maxD) dx *= dy/maxD; //extends shadow horizontally
            if (dy<maxDy) dx += (maxDy-dy)/maxDy*u_Shadows*0.01*maxDx;
            lightness = 1.0 - clamp(0.0, 1.0, u_Shadows*0.01*maxDx-dx)/maxDx;
            if (lightness>1.0) lightness=1.0;
            outColor = col*vec4(lightness, lightness, lightness, 1.0);
        }
    }

    float locIntensity = getLocus(pos, col, outColor);
    return mix(col, outColor, locIntensity);
}

#include mainWithOutPos(streak)
