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
uniform vec4 u_Color1;
uniform vec4 u_Color2;

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


float getStroke(vec2 p, vec2 c, vec2 dir, float thickness) {
    if (dir.x==0.0 && dir.y==0.0) return 0.0;
    vec2 d = normalize(dir);
    //p = mat2(d, vec2(-d.y, d.x))*(p-c);
    p = mat2(vec2(d.x, -d.y), d.yx)*(p-c);
    //p = (p-c);
    float len = length(dir);
    float l = length(vec2(max(0.0, abs(p.x)-len), p.y));
    return l<thickness ? 1.0 : 0.0;
}



vec2 response(vec2 u) {
    if (u.x==0.0 && u.y==0.0) return u;
    float len = length(u);
    len = len<u_Dampening ? 0.0 : pow((len-u_Dampening)/(1.0-u_Dampening), 0.1);
    vec2 n = normalize(u);
    return len*n;
}

vec4 gn(vec2 pos, vec2 outPos) {
    float pixel = 2.0 / u_Tex0Dim.y;
    vec2 p = vec2(pixel, 0.0);

    float sum = 0.0;
//    float max = 0.0;
//    float fRadius = u_Thickness*0.0001 / pixel;
//    int radius = int(floor(0.5 + fRadius));
//    for(int j=-radius; j<=radius; ++j) {
//        for(int i=-radius; i<=radius; ++i) {
//            vec2 delta = vec2(float(i), float(j));
//            if (length(delta)<fRadius) {
//                sum += onContour(pos + delta*vec2(pixel, pixel), p) ? 1.0 : 0.0;
//                max += 1.0;
//            }
//        }
//    }

    float resolution = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));
    float strokeLen = resolution*u_Count;
    vec2 sp = floor(pos*resolution+0.5)/resolution;
    float delta = 0.005;
    float step = 1.0/resolution;
    for(float j=-u_Count; j<=u_Count; ++j) {
        for (float i=-u_Count; i<=u_Count; ++i) {
            vec2 pp = sp + vec2(i, j)*step;
            vec2 grad = getGradient(pp, delta)*delta/2.0;
            vec2 g = response(grad) /resolution/2.0 * u_Count;
            sum += getStroke(pos, pp, vec2(g.y, -g.x), u_Thickness*0.0002);
            float style = u_Style*0.01;
            if (style<=0.5) {
                float val = sampl(pos);
                vec2 index = floor(pp*resolution);
                float k = index.x+index.y;
                if (fmod(k, 4.0)>=val*4.0) {
                    sum += getStroke(pos, pp, normalize(grad)/resolution/2.0 * u_Count, u_Thickness*0.0002*smoothstep(0.0, 0.5, style));
                }
            }
            else if (style>0.5) {
                float val = sampl(pp);
                float ratio = floor(val*5.0+0.5);
                if (ratio<5.0) {
                    vec2 index = floor((pp+20.0)*resolution);
                    float vDir = 1.0;//(fmod(ratio, 2.0)-0.5)*2.0;
                    float k = index.x-vDir*index.y;
                    if (ratio==0.0 || fmod(k, ratio)==0.0) {
                        vec2 hDir = normalize(rand2rel(index)*1.0+vec2(ratio+vDir, 1.0))/resolution/2.0 * u_Count;
                        sum += getStroke(pos, pp, hDir, u_Thickness*0.0002*smoothstep(0.5, 1.0, style));
                    }
                }
            }
        }
    }


    vec4 color;
//    color = onContour(pos, p) ? u_Color2 : u_Color1;
//    color = sum > 0.0 ? u_Color2 : u_Color1;
//    float k = pow(clamp(0.0, 1.0, sum/u_Count), 0.3);
    float k = sum>0.0 ? 1.0 : 0.0;
    color = mix(u_Color1, u_Color2, k);
    vec4 bkgCol = texture2D(u_Tex0, proj0(pos));
    vec4 mixCol = vec4(mix(bkgCol.rgb, color.rgb, color.a), bkgCol.a);

    return mix(bkgCol, mixCol, getLocus(pos, bkgCol, mixCol));
}

#include mainWithOutPos(gn)
