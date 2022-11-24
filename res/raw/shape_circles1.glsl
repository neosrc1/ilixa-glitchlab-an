precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include random

uniform float u_Thickness;
uniform float u_Count;
uniform int u_Mode;
uniform vec4 u_Color1;
uniform float u_Blur;
uniform float u_Radius;
uniform float u_Seed;
uniform float u_Variability;

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

float distToRadialTicks(vec2 p, vec2 center, int n, float r1, float r2, float angBegin, float angEnd) {
    float d = 1e10;
    float ang = angBegin;
    float dAng = (angEnd-angBegin)/float(n);
    for(int i=0; i<n; ++i) {
        float a = ang;
        if (u_Variability!=0.0) {
            a += u_Variability*0.1/float(n)*rand2relSeeded(vec2(a, a), u_Seed).x;
        }
        vec2 dir = vec2(cos(a), sin(a));
        d = min(d, distToSegment(p, center+r1*dir, center+r2*dir));
        ang += dAng;
    }
    return d;
}

float distToPiePiece(vec2 p, vec2 center, int n, float r1, float r2, float angBegin, float angEnd) {
    float d = min(
    distToArc(p, center, r1, angBegin, angEnd),
    distToArc(p, center, r2, angBegin, angEnd)
    );
    float ang = angBegin;
    float dAng = (angEnd-angBegin)/float(n);
    for(int i=0; i<n; ++i) {
        float a = ang;
        if (u_Variability!=0.0) {
            a += u_Variability*0.1/float(n)*rand2relSeeded(vec2(a, a), u_Seed).x;
        }
        vec2 dir = vec2(cos(a), sin(a));
        d = min(d, distToSegment(p, center+r1*dir, center+r2*dir));
        ang += dAng;
    }
    return d;
}

float distToPolyPiece(vec2 p, vec2 center, int n, float r1, float r2, float angBegin, float angEnd) {
    float d = 1e10;
    float ang = angBegin;
    float dAng = (angEnd-angBegin)/float(n);
    for(int i=0; i<n; ++i) {
        float a1 = ang-dAng;
        if (u_Variability!=0.0) {
            float rs = fmod(float(i-1), float(n));
            a1 += u_Variability*0.1/float(n)*rand2relSeeded(vec2(rs, rs), u_Seed).x;
        }
        vec2 dir1 = vec2(cos(a1), sin(a1));

        float a2 = ang;
        if (u_Variability!=0.0) {
            a2 += u_Variability*0.1/float(n)*rand2relSeeded(vec2(float(i), float(i)), u_Seed).x;
        }
        vec2 dir2 = vec2(cos(a2), sin(a2));

        d = min(d, distToSegment(p, center+r1*dir1, center+r2*dir1));
        d = min(d, distToSegment(p, center+r1*dir1, center+r1*dir2));
        d = min(d, distToSegment(p, center+r2*dir1, center+r2*dir2));
        ang += dAng;
    }
    return d;
}

float distToDisjointPiePieces(vec2 p, vec2 center, int n, float r1, float r2, float angBegin, float angEnd) {
    float d = 1e10;
    float ang = angBegin;
    float dAng = (angEnd-angBegin)/float(n);
    float eAng = dAng * 0.05;
    for(int i=0; i<n; ++i) {
        float a1 = ang+eAng;
        vec2 dir1 = vec2(cos(a1), sin(a1));

        float a2 = ang+dAng-eAng;
        vec2 dir2 = vec2(cos(a2), sin(a2));

        float rr2 = r2;
        if (u_Variability!=0.0) {
            float dr = u_Variability*0.01 * rand2relSeeded(vec2(float(i), float(i)), u_Seed).x;
            rr2 = max(r1, r2+dr);
        }

        d = min(d, distToSegment(p, center+r1*dir1, center+rr2*dir1));
        d = min(d, distToSegment(p, center+r1*dir2, center+rr2*dir2));
        d = min(d, distToArc(p, center, r1, a1, a2));
        d = min(d, distToArc(p, center, rr2, a1, a2));
        ang += dAng;
    }
    return d;
}

vec4 shape(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float thickness = pow(u_Thickness * 0.01, 2.0)* 0.25;
    float blur = u_Blur * 0.002;
    int m = int(fmod(float(u_Mode), 4.0));
    float d = 1e10;
    float r2 = 0.5;
    float r1 = r2 * u_Radius*0.01;
    if (m==0) d = distToPiePiece(u, vec2(0.0, 0.0), int(u_Count), r1, r2, -M_PI, M_PI);
    else if (m==1) d = distToPolyPiece(u, vec2(0.0, 0.0), int(u_Count), r1, r2, -M_PI, M_PI);
    else if (m==2) d = distToDisjointPiePieces(u, vec2(0.0, 0.0), int(u_Count), r1, r2, -M_PI, M_PI);
    else d = distToRadialTicks(u, vec2(0.0, 0.0), int(u_Count), r1, r2, -M_PI, M_PI);

    float k = response(d, thickness, blur);
    vec4 bkgCol = texture2D(u_Tex0, proj0(pos));
    return mix(vec4(mix(bkgCol.rgb, u_Color1.rgb, u_Color1.a), bkgCol.a), bkgCol, k);
}

#include mainWithOutPos(shape)
