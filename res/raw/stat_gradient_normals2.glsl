precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include random
#include locuswithcolor_nodep
#include tex(1)

uniform float u_Count;
uniform float u_Thickness;
uniform float u_Dampening;
uniform float u_Style;
uniform float u_Angle;
uniform float u_Variability;
uniform float u_Gradient;
uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform vec4 u_Color3;
uniform mat3 u_InverseModelTransform;

float sampl(vec2 pos) {
    vec4 c = texture2D(u_Tex1, proj1(pos));
    return (c.r+c.g+c.b)/3.0;
}

vec2 getGradientNormal(vec2 p, float delta) {
    vec2 d = vec2(delta, 0.0);
    vec2 gradient = vec2(
        (sampl(p+d.xy)-sampl(p-d.xy))/(delta*2.0),
        (sampl(p+d.yx)-sampl(p-d.yx))/(delta*2.0) );
    return vec2(gradient.y, -gradient.x);
}

vec2 getGradient(vec2 p, float delta) {
    vec2 d = vec2(delta, 0.0);
    vec2 gradient = vec2(
        (sampl(p+d.xy)-sampl(p-d.xy))/(delta*2.0),
        (sampl(p+d.yx)-sampl(p-d.yx))/(delta*2.0) );
    return gradient;
}


float getStroke0(vec2 p, vec2 c, vec2 dir, float thickness) {
    if (dir.x==0.0 && dir.y==0.0) return 0.0;
    vec2 d = normalize(dir);
    //p = mat2(d, vec2(-d.y, d.x))*(p-c);
    p = mat2(vec2(d.x, -d.y), d.yx)*(p-c);
    //p = (p-c);
    float len = length(dir);
    float l = length(vec2(max(0.0, abs(p.x)-len), p.y));
    return l<thickness ? 1.0 : 0.0;
}

vec2 getStroke1(vec2 p, vec2 c, vec2 dir, float thickness) {
    if (dir.x==0.0 && dir.y==0.0) return vec2(0.0, 0.0);
    vec2 d = normalize(dir);
    //p = mat2(d, vec2(-d.y, d.x))*(p-c);
    p = mat2(vec2(d.x, -d.y), d.yx)*(p-c);
    //p = (p-c);
    float len = length(dir);
    float l = length(vec2(max(0.0, abs(p.x)-len), p.y));
    float k = clamp((p.x+len)/(2.*len), 0.0, 1.0);
    return vec2(l<thickness ? 1.0 : 0.0, k);
}

vec2 perturbate0(vec2 p, vec2 dir) {
    if (u_Variability==0.0) return p;
    float len = length(dir);
    vec2 ort = vec2(dir.y, -dir.x);
    float x = dot(p, dir) / (len*len);
    float y = dot(p, ort) / (len*len);
    p += u_Variability*0.004*dir*sin(5.0*x+21.54)*cos(5.0*y+5245.24);
    p += u_Variability*0.002*dir*sin(15.0*x+0.21)*cos(15.0*y+0.575);
    p += u_Variability*0.001*dir*sin(50.0*x-1.)*cos(50.0*y+1.255);
    p += u_Variability*0.002*ort*sin(5.2*x+21.4)*cos(4.52*y+525.24);
    p += u_Variability*0.001*ort*sin(15.4*x+0.1)*cos(17.0*y+0.75);
    p += u_Variability*0.0005*ort*sin(50.7*x-1.)*cos(47.7*y+1.25);
    return p;
}

vec2 perturbate(vec2 p, vec2 dir) {
    if (u_Variability==0.0) return p;
    float M = u_Variability<0.0 ? 1.0 : 5.0;
    float len = length(dir);
    vec2 ort = vec2(dir.y, -dir.x);
    float x = dot(p, dir) / (len*len) * M;
    float y = dot(p, ort) / (len*len);
    p += u_Variability*0.004*dir*sin(1.0*x+21.54)*cos(5.0*y+5245.24);
    p += u_Variability*0.002*dir*sin(3.0*x+0.21)*cos(15.0*y+0.575);
    p += u_Variability*0.001*dir*sin(10.0*x-1.)*cos(50.0*y+1.255);
    p += u_Variability*0.002*ort*sin(1.2*x+21.4)*cos(4.52*y+525.24);
    p += u_Variability*0.001*ort*sin(3.4*x+0.1)*cos(17.0*y+0.75);
    p += u_Variability*0.0005*ort*sin(10.7*x-1.)*cos(47.7*y+1.25);
    return p;
}

vec2 perturbate1(vec2 p, vec2 c, vec2 dir) {
    if (u_Variability==0.0) return p;
    float len = length(dir);
    vec2 ort = vec2(dir.y, -dir.x);
    if (u_Variability<0.0) {
        float x = dot(p-c, dir) / (len*len);
        float k = 1. - u_Variability*0.01*x;
        float y = dot(p-c, ort) / (len*len);
        return c + dir*x + ort*y/k; // or *k
    }
    float M = u_Variability<0.0 ? 1.0 : 5.0;
    float x = dot(p, dir) / (len*len) * M;
    float y = dot(p, ort) / (len*len);
    p += u_Variability*0.004*dir*sin(1.0*x+21.54)*cos(5.0*y+5245.24);
    p += u_Variability*0.002*dir*sin(3.0*x+0.21)*cos(15.0*y+0.575);
    p += u_Variability*0.001*dir*sin(10.0*x-1.)*cos(50.0*y+1.255);
    p += u_Variability*0.002*ort*sin(1.2*x+21.4)*cos(4.52*y+525.24);
    p += u_Variability*0.001*ort*sin(3.4*x+0.1)*cos(17.0*y+0.75);
    p += u_Variability*0.0005*ort*sin(10.7*x-1.)*cos(47.7*y+1.25);
    return p;
}
vec2 getStroke(vec2 p, vec2 c, vec2 dir, float thickness) {
    if (dir.x==0.0 && dir.y==0.0) return vec2(0.0, 0.0);
    vec2 d = normalize(dir);
    //p = mat2(d, vec2(-d.y, d.x))*(p-c);
    float len = length(dir);
    p = perturbate(p, dir);
    p = mat2(vec2(d.x, -d.y), d.yx)*(p-c);
    //p = (p-c);
    float l = length(vec2(max(0.0, abs(p.x)-len), p.y));
    float k = clamp((p.x+len)/(2.*len), 0.0, 1.0);
    return vec2(l<thickness ? 1.0 : 0.0, k);
}

float luma(vec3 c) {
    return (0.2989*c.r + 0.587*c.g + 0.114*c.b);
}

vec2 response0(vec2 u) {
    if (u.x==0.0 && u.y==0.0) return u;
    float len = length(u);
    len = len<u_Dampening ? 0.0 : pow((len-u_Dampening)/(1.0-u_Dampening), 0.1);
    vec2 n = normalize(u);
    return len*n;
}

vec2 response(vec2 u) {
    if (u.x==0.0 && u.y==0.0) return u;
    float len = length(u);
    len = 1.0;
    vec2 n = normalize(u);
    return len*n;
}

vec4 gn0(vec2 pos, vec2 outPos) {
    float pixel = 2.0 / u_Tex0Dim.y;
    vec2 p = vec2(pixel, 0.0);

    float k = 0.0;
    float strokeIntensity = 0.0;
    float resolution = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    float strokeLen = resolution*u_Count;
    vec2 sp = floor(pos*resolution+0.5)/resolution;
    float delta = 0.005;
    float step = 1.0/resolution;
    float maxI, maxJ;
    for(float j=-u_Count; j<=u_Count; ++j) {
        for (float i=-u_Count; i<=u_Count; ++i) {
            vec2 pp = sp + vec2(i, j)*step;
            vec2 grad = getGradient(pp, delta)*delta/2.0;
            vec2 g = response(grad) /resolution/2.0 * u_Count;
            vec2 st = getStroke(pos, pp, vec2(g.y, -g.x), u_Thickness*0.0002);
            if (st.x>strokeIntensity) {
                strokeIntensity = st.x;
                k = st.y;
                maxI = i;
                maxJ = j;
            }
        }
    }


    vec4 color;
    color = mix(u_Color1, u_Color2, k*strokeIntensity);
    vec4 bkgCol = texture2D(u_Tex0, proj0(sp+ vec2(maxI, maxJ)*step));
    vec4 mixCol = vec4(mix(bkgCol.rgb, color.rgb, color.a), bkgCol.a);

    return mix(bkgCol, mixCol, getLocus(pos, bkgCol, mixCol));
}

vec4 gn1(vec2 pos, vec2 outPos) {
    float pixel = 2.0 / u_Tex0Dim.y;
    vec2 p = vec2(pixel, 0.0);

    float k = 0.0;
    float strokeIntensity = 0.0;
    float resolution = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    float strokeLen = resolution*u_Count;
    vec2 sp = floor(pos*resolution+0.5)/resolution;
    float delta = 0.005;
    float step = 1.0/resolution;
    vec4 curColor = vec4(0.0);
    float n = 0.;
    mat2 rot = mat2(cos(u_Angle), sin(u_Angle), -sin(u_Angle), cos(u_Angle));
    for(float j=-u_Count; j<=u_Count; ++j) {
        for (float i=-u_Count; i<=u_Count; ++i) {
            vec2 pp = sp + vec2(i, j)*step;
            vec2 grad = getGradient(pp, delta)*delta/2.0;
            vec2 g = response(grad) /resolution/2.0 * u_Count;
            vec2 st = getStroke(pos, pp, rot * g, u_Thickness*0.01/resolution);
            if (st.x>=strokeIntensity) { // source of problem - for some reason the correct values get overriten => count tracing?
                ++n;
                strokeIntensity = st.x;
//                vec4 color = vec4(st.x, st.y, n*0.1, 1.0);
                vec4 color = vec4(vec3(n*0.1), 1.0);
//                vec4 color = mix(u_Color2, u_Color3, st.y);
//                if (color.a<1.0) {
//                    vec4 bkgCol = texture2D(u_Tex0, proj0(pp));
//                    color = vec4(mix(bkgCol.rgb, color.rgb, color.a), bkgCol.a);
//                }
                if (luma(color.rgb) >= luma(curColor.rgb)) curColor = color;
//                curColor = color;
            }
        }
    }

    vec4 bkgCol = texture2D(u_Tex0, proj0(pos));
    curColor = mix(u_Color1, curColor, strokeIntensity);
    curColor = vec4(mix(bkgCol.rgb, curColor.rgb, curColor.a), mix(bkgCol.a, curColor.a, curColor.a));
    return mix(bkgCol, curColor, getLocus(pos, bkgCol, curColor));
}

vec4 gn(vec2 pos, vec2 outPos) {
    float pixel = 2.0 / u_Tex0Dim.y;
    vec2 p = vec2(pixel, 0.0);

    float k = 0.0;
    float strokeIntensity = 0.0;
    float resolution = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
//    vec2 sp = floor(pos*resolution + u_ModelTransform[2].xy)/resolution;
    vec2 sp = floor(pos*resolution+0.5)/resolution - fract(u_ModelTransform[2].xy)/resolution;
//    vec2 sp = floor((u_ModelTransform * vec3(pos, 1.0)).xy);
    float delta = 0.02;
    float step = 1.0/resolution;
    vec4 curColor = vec4(0.0, 0.0, 0.0, 1.0);
    float n = 0.;
    float gradient = u_Gradient * 0.05;
    float ang = u_Angle + 1.57079;
    mat2 rot = mat2(cos(ang), sin(ang), -sin(ang), cos(ang));
    for(float j=-u_Count; j<=u_Count; ++j) {
        for (float i=-u_Count; i<=u_Count; ++i) {
//            vec2 pp = (u_InverseModelTransform * vec3(sp + vec2(i, j)*step, 1.0)).xy;
            vec2 pp = sp + vec2(i, j)*step;
            vec2 grad = getGradient(pp, delta)*delta/2.0;
            vec2 g = rot * (response(grad) /resolution/2.0 * u_Count);
            //            vec2 st = getStroke(pos, pp, vec2(g.x, g.y), u_Thickness*0.01/resolution);
            vec2 st = getStroke(pos, pp, g, u_Thickness*0.01/resolution);
            if (st.x>0.) { // source of problem - for some reason the correct values get overriten => count tracing?
                ++n;
                strokeIntensity = max(strokeIntensity, st.x);
                //                vec4 color = vec4(st.x, st.y, n*0.1, 1.0);
                //                vec4 color = vec4(vec3(n*0.1), 1.0);
                float kGrad = (st.y-0.5)*gradient + 0.5;
                //                vec4 color = mix(u_Color2, u_Color3, kGrad);
                float alpha = mix(u_Color2.a, u_Color3.a, st.y);
                vec4 color = vec4(mix(u_Color2.rgb, u_Color3.rgb, mix(st.y, kGrad, min(u_Color2.a, u_Color3.a))), alpha);
                if (color.a<1.0) {
                    //                    vec4 bkgCol = texture2D(u_Tex0, proj0(pp));
                    vec4 bkgCol = mix(texture2D(u_Tex0, proj0(pp-g*.5*gradient)), texture2D(u_Tex0, proj0(pp+g*.5*gradient)), 0.5);
                    color = vec4(mix(bkgCol.rgb, color.rgb, color.a), bkgCol.a);
                }
                if (luma(color.rgb) >= luma(curColor.rgb)) curColor = color;
                //                curColor.rgb += color.rgb;
            }
        }
    }

    vec4 bkgCol = texture2D(u_Tex0, proj0(pos));
    curColor = mix(u_Color1, curColor, strokeIntensity);
    curColor = vec4(mix(bkgCol.rgb, curColor.rgb, curColor.a), mix(bkgCol.a, curColor.a, curColor.a));
    return mix(bkgCol, curColor, getLocus(pos, bkgCol, curColor));
}


#include mainWithOutPos(gn)
