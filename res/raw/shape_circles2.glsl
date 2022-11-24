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

float distToRadialTicks(vec2 p, vec2 center, int n, float r1, float r2, float angBegin, float angEnd, float varia) {
    float d = 1e10;
    vec2 centerToP = p-center;
    float ang = getVecAngle(centerToP);
    float dAng = (angEnd-angBegin)/float(n);
    float nd = floor(ang/dAng);

    if (varia!=0.0) {
        if (ang<-M_PI+dAng/2.0 && fmod(float(n), 2.0)==1.0) nd = floor((ang+2.0*M_PI)/dAng);
        float dr = varia * rand2relSeeded(vec2(float(nd), float(nd)), u_Seed).x;
        r2 = max(r1, r2+dr);
    }

    vec2 dir = vec2(cos((nd+0.5)*dAng), sin((nd+0.5)*dAng));
    d = min(d, distToSegment(p, center+r1*dir, center+r2*dir));

    return d;
}

float distToPiePiece(vec2 p, vec2 center, int n, float r1, float r2, float angBegin, float angEnd) {
    float d = min(
        distToArc(p, center, r1, angBegin, angEnd),
        distToArc(p, center, r2, angBegin, angEnd)
    );
    vec2 centerToP = p-center;
    float ang = getVecAngle(centerToP);
    float dAng = (angEnd-angBegin)/float(n);
    float nd = floor(ang/dAng);

    vec2 dir = vec2(cos((nd+0.5)*dAng), sin((nd+0.5)*dAng));
    d = min(d, distToSegment(p, center+r1*dir, center+r2*dir));

    return d;
}

float distToPolyPiece(vec2 p, vec2 center, int n, float r1, float r2, float angBegin, float angEnd) {
    float d = 1e10;
    vec2 centerToP = p-center;
    float ang = getVecAngle(centerToP);
    float dAng = (angEnd-angBegin)/float(n);
    float nd = floor(ang/dAng);

    float a1 = nd*dAng;
    vec2 dir1 = vec2(cos(a1), sin(a1));

    float a2 = nd*dAng+dAng;
    vec2 dir2 = vec2(cos(a2), sin(a2));

    d = min(d, distToSegment(p, center+r1*dir1, center+r2*dir1));
    d = min(d, distToSegment(p, center+r1*dir2, center+r2*dir2));
    d = min(d, distToSegment(p, center+r2*dir1, center+r2*dir2));
    d = min(d, distToSegment(p, center+r1*dir1, center+r1*dir2));

    return d;
}

float distToDisjointPiePieces(vec2 p, vec2 center, int n, float r1, float r2, float angBegin, float angEnd, float varia) {
    float d = 1e10;
    vec2 centerToP = p-center;
    float ang = getVecAngle(centerToP);
    float dAng = (angEnd-angBegin)/float(n);
//    float eAng = dAng * 0.075;
    float eAng = dAng * 0.1;
    float nd = floor(ang/dAng);

    float a1 = nd*dAng+eAng;
    vec2 dir1 = vec2(cos(a1), sin(a1));

    float a2 = nd*dAng+dAng-eAng;
    vec2 dir2 = vec2(cos(a2), sin(a2));
    if (varia!=0.0) {
        if (ang<-M_PI+dAng/2.0 && fmod(float(n), 2.0)==1.0) nd = floor((ang+2.0*M_PI)/dAng);
        float dr = varia * rand2relSeeded(vec2(float(nd), float(nd)), u_Seed).x;
        if (varia>0.0) r2 = max(r1, r2+dr);
        else r1 = max(0.0, min(r2, r1+dr));
    }

    d = min(d, distToSegment(p, center+r1*dir1, center+r2*dir1));
    d = min(d, distToSegment(p, center+r1*dir2, center+r2*dir2));
    d = min(d, distToArc(p, center, r1, a1, a2));
    d = min(d, distToArc(p, center, r2, a1, a2));

    return d;
}

vec4 shape(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).yx;

    float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[1][0]));

    float thickness = pow(u_Thickness * 0.01, 2.0)* 0.25 * scale;
    float blur = u_Blur * 0.002 * scale;

    float varia = u_Variability*0.01;
    int m = u_Mode;//int(fmod(float(u_Mode), 4.0));
    float d = 1e10;
    float r2 = 0.5;
    float r1 = r2 * u_Radius*0.01;
    if (m==0) d = distToPiePiece(u, vec2(0.0, 0.0), int(u_Count), r1, r2, -M_PI, M_PI);
    else if (m==1) d = distToPolyPiece(u, vec2(0.0, 0.0), int(u_Count), r1, r2, -M_PI, M_PI);
    else if (m==2) d = distToDisjointPiePieces(u, vec2(0.0, 0.0), int(u_Count), r1, r2, -M_PI, M_PI, varia);
    else if (m==3) d = distToRadialTicks(u, vec2(0.0, 0.0), int(u_Count), r1, r2, -M_PI, M_PI, varia);
    else {
        int count = int(fmod(float(u_Mode), 5.0)+2.0);
        vec2 rnd = rand2relSeeded(vec2(u_Mode, u_Mode), 0.0);
        for(int i=0; i<count; ++i) {
            m = int(fmod(4.0*(rnd.y+0.5), 4.0));
            float kv = floor(rnd.y*2.0+0.5)-0.5;
            if (m==0) d = min(d, distToPiePiece(u, vec2(0.0, 0.0), int(u_Count), r1, r2, -M_PI, M_PI));
            else if (m==1) d = min(d, distToPolyPiece(u, vec2(0.0, 0.0), int(u_Count), r1, r2, -M_PI, M_PI));
            else if (m==2) d = min(d, distToDisjointPiePieces(u, vec2(0.0, 0.0), int(u_Count), r1, r2, -M_PI, M_PI, varia*kv));
            else d = min(d, distToRadialTicks(u, vec2(0.0, 0.0), int(u_Count), r1, r2, -M_PI, M_PI, varia*kv));
            float scale = 0.5 + 0.9*rnd.x;
            if (scale<0.05) break;
            r1 *= scale;
            r2 *= scale;
            rnd = rand2relSeeded(rnd, 0.0);
        }
    }

    float k = response(d, thickness, blur);
    float gg = 0.025*max(0.0, u_Blur-50.0) *pow(1.0-k, 10.0); //0.05*max(0.0, u_Blur-50.0) * (d<=thickness ? 1.0 : 0.0);
    float addK = smoothstep(50.0, 100.0, u_Blur);
    vec4 bkgCol = texture2D(u_Tex0, proj0(pos));
    vec4 targetCol = vec4(mix(bkgCol.rgb, (u_Color1.rgb+vec3(gg, gg, gg))*(gg+1.0), u_Color1.a), bkgCol.a);
    vec4 outCol = mix(mix(targetCol, bkgCol, k), targetCol*(1.0-k)+bkgCol, addK);

    return mix(bkgCol, outCol, getLocus(pos, bkgCol, outCol));
}

#include mainWithOutPos(shape)
