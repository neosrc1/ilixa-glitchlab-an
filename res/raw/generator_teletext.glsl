precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include perspective

uniform float u_Variability;
uniform float u_PosterizeCount;


vec4 sixCol(float x) {
    if (x<0.1666667) {
        return vec4(1.0, 0.0, 0.0, 1.0);
    }
    else if (x<0.3333333) {
        return vec4(0.0, 1.0, 0.0, 1.0);
    }
    else if (x<0.5) {
        return vec4(0.0, 0.0, 1.0, 1.0);
    }
    else if (x<0.6666666) {
        return vec4(1.0, 1.0, 0.0, 1.0);
    }
    else if (x<0.8333333) {
        return vec4(0.0, 1.0, 1.0, 1.0);
    }
    else  {
        return vec4(1.0, 0.0, 1.0, 1.0);
    }
}

vec4 bw(float x) {
    return x<0.0 ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(1.0, 1.0, 1.0, 1.0);
}

vec4 style0(vec2 u) {
    return sixCol(fmod(u.x, 1.0));
}

vec4 style1(vec2 u) {
    float g = (floor(fmod(u.x, 1.0)*2.0) + floor(fmod(u.y, 1.0)*2.0)*2.0)/4.0;
    return vec4(g, g, g, 1.0);//bw(floor(fmod((xx*xx), 2.0))-1.0);
}

vec4 style2(vec2 u) {
    return sixCol(fmod(u.y, 1.0));
}

vec4 style3(vec2 u) {
//return vec4(1.0, 0.0, 1.0, 1.0);
    float xx = fmod(u.x, 1.0)*5.0;
    return bw(floor(fmod((xx*xx), 2.0))-1.0);
}

vec4 teletext(vec2 pos, vec2 outPos) {

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    if (u_Variability>0.0) {
        vec2 d = vec2(1.0, 1.0);
        if (u_Variability>30.0) {
            float k = (u_Variability-30.0)/50.0;
            d = vec2(1.0 + k*sin(u.x+u.y*u.y), 1.0 + k*sin(u.y-u.x*u.x));
        }
        u += u_Variability * d * vec2(sin(u.x*M_PI*0.0201*u_Variability*133.2), sin(u.y*M_PI*0.01998*u_Variability+454.2));
    }

    int style = int(1.0+0.999999*sin(u.x*M_PI)) + 2*int(1.0+0.999999*sin(u.y*M_PI));
    if (style == 0) {
        return style0(u);
    }
    else if (style == 1) {
        return style3(u);
    }
    else if (style == 2) {
        return style1(u);
    }
    else { //if (style == 3) {
        return style2(u);
    }


}

#include mainWithOutPosAndPerspectiveFit(teletext)
