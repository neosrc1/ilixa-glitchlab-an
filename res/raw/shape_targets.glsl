precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include random
#include locuswithcolor_nodep

uniform float u_Thickness;
uniform float u_Count;
uniform int u_Mode;
uniform vec4 u_Color1;
uniform float u_Blur;
uniform float u_Radius;
uniform float u_Seed;
uniform float u_Variability;

float min3(float a, float b, float c) { return min(min(a, b), c); }
float min4(float a, float b, float c, float d) { return min(min(a, b), min(c ,d)); }

float distance(float x) {
    if (abs(x)>0.5) return abs(x)-0.5;

    float normalized = ((x+0.5)*u_Count + 0.5);
    return abs(fract(normalized)-0.5)/u_Count;
}

float response(float d, float thickness, float blur) {
    return  pow(smoothstep(thickness, thickness+blur, d), 0.3);
}

float distToSegment(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b-a;
    float abLen = length(ab);
    if (abLen==0.0) return length(p-a);
    vec2 abNorm = ab/abLen;
    vec2 ap = p-a;
    float abProj = dot(ap, abNorm);
    if (abProj>=0.0 && abProj<=abLen) {
        return abs(dot(ap, vec2(abNorm.y, -abNorm.x)));
    }
    else {
        return min(length(ap), length(p-b));
    }
}
float distToFullCircle(vec2 p, vec2 center, float radius) {
    return max(0.0, (length(p-center)-radius));
}

float distToArc(vec2 p, vec2 center, float radius, float angBegin, float angEnd) {
    float angle = getVecAngle(p-center);
    if (angle>=angBegin && angle<=angEnd) {
        return abs(length(p-center)-radius);
    }
    else {
        vec2 a = center + radius*vec2(cos(angBegin), sin(angBegin));
        vec2 b = center + radius*vec2(cos(angEnd), sin(angEnd));
        return min(length(p-a), length(p-b));
    }
}

/*float distToCross(vec2 p, vec2 center, float radius) {
    vec2 delta = vec2(radius, 0.0);
    return min(distToSegment(p, center-delta, center+delta), distToSegment(p, center-delta.yx, center+delta.yx));
}*/

float distToCrossPartial(vec2 p, vec2 center, float r1, float r2 ) {
    p = abs(p);
    p = vec2(max(p.x, p.y), min(p.x, p.y));
    return length(p - center - vec2(clamp(r1, r2, p.x), 0.0));
}

float distToSquare(vec2 p, vec2 center, float radius) {
    p = abs(p-center);
    p = vec2(max(p.x, p.y), min(p.x, p.y));
    return length(p - vec2(radius, clamp(0.0, radius, p.y)));
}

float distToRect(vec2 p, vec2 center, float rx, float ry) {
    float radius = min(rx, ry);
    p = abs(p-center);
    if (rx>ry) {
        p.x = max(0.0, p.x-rx+ry);
    }
    else {
        p.y = max(0.0, p.y-ry+rx);
    }
    p = vec2(max(p.x, p.y), min(p.x, p.y));
    return length(p - vec2(radius, clamp(0.0, radius, p.y)));
}

float distToDottedSquare(vec2 p, vec2 center, float radius) {
    return min(
        distToSquare(p, center, radius),
        0.5*distToFullCircle(p, center, radius*0.0001) );
}

float distToDottedRect(vec2 p, vec2 center, float rx, float ry) {
    return min(
        distToRect(p, center, rx, ry),
        0.5*distToFullCircle(p, center, min(rx, ry)*0.0001) );
}

float distToRadialTicks2(vec2 p, vec2 center, int n, float r1, float r2, float angBegin, float angEnd) {
    float d = 1e10;
    vec2 centerToP = p-center;
    float ang = getVecAngle(centerToP);
    float dAng = (angEnd-angBegin)/float(n);
    float nd = floor(ang/dAng);

    vec2 dir1 = vec2(cos((nd)*dAng), sin((nd)*dAng));
    vec2 dir2 = vec2(cos((nd+1.0)*dAng), sin((nd+1.0)*dAng));
    d = min(d, distToSegment(p, center+r1*dir1, center+r2*dir1));
    d = min(d, distToSegment(p, center+r1*dir2, center+r2*dir2));

    return d;
}

float distToTarget1(vec2 p, vec2 center, float r) {
    return min(
    distToSquare(p, center, r*0.3),
    distToCrossPartial(p, center, r*0.3, r));
}

float distToTarget2(vec2 p, vec2 center, float r) {
    return min(
    distToArc(p, center, r*0.5, -M_PI, M_PI),
    distToCrossPartial(p, center, r*0.5, r));
}

float distToTarget3(vec2 p, vec2 center, float r) {
    return min4(
    distToArc(p, center, r*0.3, -M_PI+0.5, -0.5),
    distToArc(p, center, r*0.3, 0.5, M_PI-0.5),
    distToCrossPartial(p, center, r*0.3, r),
    distToFullCircle(p, center, r*0.1)
    );
}

float distToTarget4(vec2 p, vec2 center, float r) {
    return min4(
    distToArc(p, center, r*0.15, -M_PI, M_PI),
    distToArc(p, center, r*0.3, -M_PI, M_PI),
    distToArc(p, center, r*0.45, -M_PI, M_PI),
    distToCrossPartial(p, center, r*0.15, r)
    );
}

float distToTarget5(vec2 p, vec2 center, float r) {
    return min3(
    distToRadialTicks2(p, center, 32, r*0.3, r*0.45, -M_PI, M_PI),
    distToRadialTicks2(p, center, 8, r*0.3, r*0.6, -M_PI, M_PI),
    distToCrossPartial(p, center, r*0.3, r)
    );
}

float distToTarget6(vec2 p, vec2 center, float r) {
    vec2 c = vec2(0.0, 0.0);
    vec2 dx = vec2(0.25, 0.0);
    vec2 dy = vec2(0.0, 0.15);
    p = abs(p);
    return min(
        min(distToDottedSquare(p, c, r),
            distToDottedRect(p, c + 2.0*dy, r, r*0.7) ),
        min(distToDottedRect(p, c + 2.0*dx , r*0.7, r),
        distToDottedRect(p, c + dx+dy, r*0.7, r) ) );
}

float distToTarget7(vec2 p, vec2 center, float r, float m) {
    float d = 1e10;
    vec2 c = vec2(0.0, 0.0);
    p = abs(p-center);
    if (fmod(m, 2.0)>=1.0) d = min(d, distToCrossPartial(p, c, r*0.3, r));
    m /= 2.0;
    if (fmod(m, 2.0)>=1.0) d = min(d, distToRadialTicks2(p, c, 32, r*0.3, r*0.45, -M_PI, M_PI));
    m /= 2.0;
    if (fmod(m, 2.0)>=1.0) d = min(d, distToRadialTicks2(p, c, 8, r*0.3, r*0.6, -M_PI, M_PI));
    m /= 2.0;
    if (fmod(m, 2.0)>=1.0) d = min(d, distToSquare(p, c, r*0.5));
    m /= 2.0;
    if (fmod(m, 2.0)>=1.0) d = min(d, distToSquare(p, c, r*0.3));
    m /= 2.0;
    if (fmod(m, 2.0)>=1.0) d = min(d, distToArc(p, c, r*0.5, -M_PI, M_PI));
    m /= 2.0;
    if (fmod(m, 2.0)>=1.0) d = min(d, distToArc(p, c, r*0.3, -M_PI, M_PI));
    m /= 2.0;
    if (fmod(m, 3.0)>=2.0) d = min(d, distToSquare(p, vec2(r*0.5, r*0.5), r*0.1));
    else if (fmod(m, 3.0)>=1.0) d = min(d, distToArc(p, vec2(r*0.5, r*0.5), r*0.1, -M_PI, M_PI));
    m /= 3.0;
    if (fmod(m, 3.0)>=2.0) d = min(d, distToSquare(p, vec2(r*0.8, 0.0), r*0.1));
    else if (fmod(m, 3.0)>=1.0) d = min(d, distToArc(p, vec2(r*0.8, 0.0), r*0.1, -M_PI, M_PI));
    m /= 3.0;

    return d;
}

vec4 shape(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[1][0]));

    float thickness = pow(u_Thickness * 0.01, 2.0)* 0.25 * scale;
    float blur = u_Blur * 0.002 * scale;
    int m = u_Mode;//int(fmod(float(u_Mode), 6.0));
    float d = 1e10;
    float r2 = 0.5;
    float r1 = r2 * u_Radius*0.01;
    if (m==0) d = distToTarget6(u, vec2(0.0, 0.0), 0.035);//u_Radius*0.001);
    else if (m==1) d = distToTarget1(u, vec2(0.0, 0.0), r2);
    else if (m==2) d = distToTarget2(u, vec2(0.0, 0.0), r2);
    else if (m==3) d = distToTarget3(u, vec2(0.0, 0.0), r2);
    else if (m==4) d = distToTarget4(u, vec2(0.0, 0.0), r2);
    else if (m==5) d = distToTarget5(u, vec2(0.0, 0.0), r2);
    else d = distToTarget7(u, vec2(0.0, 0.0), r2, float(u_Mode));

    float k = response(d, thickness, blur);
    float gg = 0.025*max(0.0, u_Blur-50.0) *pow(1.0-k, 10.0); //0.05*max(0.0, u_Blur-50.0) * (d<=thickness ? 1.0 : 0.0);
    float addK = smoothstep(50.0, 100.0, u_Blur);
    vec4 bkgCol = texture2D(u_Tex0, proj0(pos));
    vec4 targetCol = vec4(mix(bkgCol.rgb, (u_Color1.rgb+vec3(gg, gg, gg))*(gg+1.0), u_Color1.a), bkgCol.a);
    vec4 outCol = mix(mix(targetCol, bkgCol, k), targetCol*(1.0-k)+bkgCol, addK);

    return mix(bkgCol, outCol, getLocus(pos, bkgCol, outCol));

}

#include mainWithOutPos(shape)
