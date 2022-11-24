precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform vec4 u_Color3;
uniform vec4 u_Color4;
uniform float u_Count;
uniform float u_Blur;
uniform float u_Height;
uniform float u_Lights;
uniform float u_Columns;
uniform float u_Seed;
uniform float u_Reflectivity;

float rand11(float x) {
    return rand2rel(vec2(x, x)).x*2.0; //(2.0*fract((fract(x*172.237-271.4143)+23.773)*434.74438))-1.0;
}

float rand21(vec2 u) {
    return rand2rel(u).x*2.0; //(2.0*fract((fract(u.x*113.237+10.4343+u.y)+23.773+10.565*u.y-u.x)*434.4438))-1.0;
}

vec4 blend(vec4 a, vec4 b) {
    return vec4(mix(vec3(a), vec3(b), b.a), max(a.a, b.a));
}

float lineDist(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p-a;
    vec2 ba = b-a;
    float t = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 1.0);
    return length(pa - ba*t);
}

float rectDist(vec2 p, float width, float height) {
    p = abs(p);
    return length(p-vec2(clamp(p.x, 0.0, width/2.0), clamp(p.y, 0.0, height/2.0)));
}

float rectDistTrue(vec2 p, float width, float height) {
    p = abs(p);
    if (p.x<width/2.0 && p.y<height/2.0) {
        return -min(width/2.0-p.x, height/2.0-p.y);
    }
    else {
		return length(p-vec2(clamp(p.x, 0.0, width/2.0), clamp(p.y, 0.0, height/2.0)));
    }
}

float eqTriangleDist(vec2 p, float r) {
    vec2 n = vec2(-0.8660254, 0.5);
    p.y = abs(p.y);
    float d = dot(p, n);
    if (d>0.0) {
        p -= 2.0*d*n;
    }
    //p.y = abs(p.y);
    float Y = r*0.8660254;
    return sign(p.x-r) * length(p-vec2(r, clamp(p.y, -Y, Y)));
}


float catDist(vec2 u) {
    float c = 100000.0;
    u += vec2(-0.015, 0.03);
    float hr = 0.005;
    c = min(c, length(u)-hr); // head
    vec2 earL = vec2(0.003, -0.0035);
    vec2 earR = vec2(-0.003, -0.0035);
    c = min(c, eqTriangleDist(-(u+earL), 0.002));
    c = min(c, eqTriangleDist(u+earR, 0.002));
    u.y += 0.0125;
    float br = 0.01;
    c = min(c, length(u*vec2(1.3+u.y*15.0, 1.0))-br); // body
    u += 0.007;
    float tr = 0.0015;
    c = min(c, lineDist(u, vec2(-hr, 0.0), vec2(br, 0.0))-tr); // tail
    return c;
}

//float blindsDist(vec2 u, float N) {
//    float d = 10000.0;
//    float s = 200.0;
//    float idy = floor(u.y*s+0.5);
//    u.y -= idy/s;
//    d = idy>N ? min(d, rectDistTrue(u, 0.058, 0.004)) : d;
//    return d;
//}

float getHeight0(float i) {
    //    float r = clamp(rand11(i), 0.0, 1.0);
    float r = abs(rand11(i));
    float h = 1.0+r*10.0;
    float rr = fract(r*10.0);
    float r1 = u_Height*0.1;
    float r2 = 1.0-u_Height;
    if (rr<r1) {
        rr = rr/r1;
        h += rr*40.0;
    }
    else if (rr>r2) {
        rr = (rr-r2)/u_Height;
        h += rr*15.0;
    }
    //float h = r*10.0;
    //if (h>8.0 && fract(h)>0.81) h*=1.0+(fract(r)-0.8)*(fract(r)-0.8)*25.0;
    //else if (h>8.0 && fract(r)<0.1) h *= 3.0;
    return h;
}

float getHeight1(float i) {
    float r = abs(rand11(i));
    float h = 1.0+r*10.0;
    float r1 = u_Height*1.0;
    float r2 = r1*0.1;
    if (h>11.0*(1.0-r2)) {
        float rr = 11.0-h;
        h += rr*40.0;
    }
    else if (h>11.0*(1.0-r2)) {
        float rr = 11.0-h;
        h += rr*1.5;
    }
    return h;
}

float getHeight(float i) {
    vec2 rnd = rand2rel(vec2(i, i)) + 0.5;
    float h = 1.0+rnd.x*10.0;
    float growth = smoothstep(0.5, 1.0, pow(rnd.y, 10.0-9.0*+u_Height));
    float boost = 1.0+2.0*smoothstep(0.9, 1.0, rnd.x*rnd.y);
    h += u_Height*growth*boost*25.0;
    return h;
}

float mergeRect(float a, float dist, float blur) {
    return max(smoothstep(blur, 0.0, dist), a);
}

vec4 layer(vec2 u, vec4 color, vec4 windowColor, vec4 columnColor, float blur) {
    float a = smoothstep(blur, 0.0, u.y);
    vec2 id = floor(u);
    float height = getHeight(id.x);
    float height1 = getHeight(id.x-1.0);
    float height2 = getHeight(id.x+1.0);
    vec2 v = fract(u);
    vec4 col = color;
    vec2 rnd = rand2relSeeded(id.xx*0.11, u_Seed)*2.0;
    float occupied = sign(rnd.x+u_Lights)*rnd.x*rnd.x*u_Lights;

    float lightColumn = 0.0;

    if (u.y>0.0 && u.y<height/2.0) { // windows
        vec2 wRatio = vec2(5.0, 3.0);
        vec2 v = (u-vec2(0.0, height/2.0)+0.5)*wRatio;
        vec2 id = floor(v+0.5);
        float windowSize = 0.3-u_Blur;
        float rndW = abs(rand21(id));
        if (id.y>-height/2.0*3.0+3.0 && abs(rndW)<occupied*1.0*u_Lights) {
            float catDist = fract(rndW*10.0)>0.99 ? 3.0*catDist((v-id)/wRatio) : 10000.0;
            //float blDist = fract(rndW*rndW)>0.2 ? 3.0*blindsDist((v-id)/wRatio, 8.0-fract(rndW*30.0)*15.0) : 10000.0;
            float windowLight = smoothstep(blur*3.0, 0.0, max(-catDist, rectDist(v-id, windowSize, windowSize)));
            col = mix(col, windowColor, clamp(windowLight, 0.0, 1.0));
        }
    }
    else if (height<2.0 && u.y>height/2.0 && abs(rnd.y)>1.0-u_Columns) { // column
        lightColumn = 20.0/(10.0+max(0.0, u.y-height))*0.5*smoothstep(0.5, 0.3, abs(u.x-floor(u.x)-0.5));
    }

    a = max(smoothstep(blur, 0.0, rectDist(u-vec2(id.x+0.5, 0.0), 1.0, height)), a);
    a = max(smoothstep(blur, 0.0, rectDist(u-vec2(id.x-0.5, 0.0), 1.0, height1)), a);
    a = max(smoothstep(blur, 0.0, rectDist(u-vec2(id.x+1.5, 0.0), 1.0, height2)), a);

    if (height>11.0) { // antenna
        if (rnd.y<0.3) {
            a = mergeRect(a, rectDist(u-vec2(id.x+0.5, 0.0), 0.125-blur, height+4.0), blur);
            if (rnd.x>0.9) {
                a = max(smoothstep(blur, 0.0, catDist(u-vec2(id.x+0.5+(rnd.y*0.04), (height+4.0)/2.0+0.051))), a);
                //a = max(smoothstep(0.5, 0.1, length(u-vec2(id.x+0.5, (height+4.0)/2.0))), a);
            }
        }
        else if (rnd.y<0.45) {
            a = mergeRect(a, rectDist(u-vec2(id.x+0.75, 0.0), 0.125-blur, height+3.0), blur);
            a = mergeRect(a, rectDist(u-vec2(id.x+0.25, 0.0), 0.125-blur, height+3.0), blur);
        }
    }

    //col.rg = abs(rand2relSeeded(id.xx*0.11, u_Seed)+0.5);

    return vec4(col.rgb, a) + 2.5*lightColumn*columnColor;//vec4(columnColor.rgb, lightColumn);
}

float stars(vec2 u) {
    u *= 100.0;
    vec2 id = floor(u);
    vec2 rnd = rand2relSeeded(id, u_Seed);
    float r = abs(rnd.x+rnd.y);
    vec2 delta = rnd*0.35;
    float radius = pow(r, 30.0)*0.5;
    return radius<=0.0 ? 0.0 : smoothstep(radius, 0.0, length(u-id-0.5+delta));
}

float clouds(vec2 u, float blur) {
    u *= 4.0;
    float cover = 1.0;
    for(float j=-1.0; j<=1.0; ++j) {
        for(float i=-4.0; i<=4.0; ++i) {
            vec2 id = floor(u)+vec2(i, j);
            vec2 rnd = rand2relSeeded(id, u_Seed);
            float r = abs(rnd.x+rnd.y);
            vec2 delta = rnd;
            vec2 radius = vec2(rnd.x*3.0, 0.0);
            cover = min(cover, smoothstep(0.0, blur, lineDist(u, id+0.5+delta-radius, id+0.5+delta+radius)));
            cover *= smoothstep(0.0, blur, lineDist(u, id+0.5+delta-radius, id+0.5+delta+radius));
        }
    }
    return cover;
}

vec4 city(vec2 uv, vec2 outPos) {
    vec4 sunColor = u_Color1;
    vec4 buildingColor = u_Color2;
    vec4 skyColor = u_Color3;
    vec4 windowColor = u_Color4;
    vec4 warmSkyColor = mix(sunColor, skyColor, 0.5);
    float panningSpeed = 8.0;

    // Normalized pixel coordinates (from 0 to 1)
    float Y = 0.0;
    //uv*=2.0;
    //vec2 panning = (u_ModelTransform*vec3(0.0, 0.0, 0.0)).xy;
    vec2 panning = vec2(u_ModelTransform[2][0], u_ModelTransform[2][1])*1.0;
    float cameraScale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[0][1]));

    float reflected = 0.0;
    float reflectY = -(Y+panning.y*panningSpeed)/4.0/cameraScale;
    if (uv.y<reflectY) {
        uv.y = 2.0*reflectY - uv.y;
        reflected = 1.0-u_Reflectivity*0.01;
    }

    vec4 bkg = mix(warmSkyColor, skyColor, clamp(0.0, 1.0, uv.y*2.0-0.25));
    float skyDamp = smoothstep(0.3, 0.05, (bkg.r+bkg.g+bkg.b)*0.333);
    float cloudDamp = 1.0;//clouds(uv, u_Blur);

    bkg = mix(bkg, windowColor*2.0, stars(uv)*skyDamp*cloudDamp);

    float sunDist = smoothstep(0.275+u_Blur*0.2, 0.275-u_Blur*0.2, length(uv));
    bkg = mix(bkg, sunColor, sunDist*cloudDamp);

    uv*=cameraScale;

    vec4 color = bkg;


    float N = u_Count;
    for(float i=N; i>0.0; --i) {
        float layerRatio = N==1.0?0.0:(i-1.0)/(N-1.0);
        vec4 building = mix(buildingColor, warmSkyColor, layerRatio);
        vec4 window = mix(windowColor, warmSkyColor, layerRatio);
        vec4 column = vec4(mix(windowColor, warmSkyColor, layerRatio*0.3).rgb, max(0.0, 0.6-layerRatio));
        float scale = 2.0+2.0*i;
        float offset = 415.24*rand11(i);
        color = blend(color, layer(
        uv*scale + vec2(offset, Y) + panning*panningSpeed, //vec2(offset+panning.x*panningSpeed, Y+panning.y*panningSpeed),
        building,
        window,
        column,
        u_Blur));
    }

    color = mix(color, buildingColor, reflected);

    return color;
}

#include mainWithOutPos(city)
