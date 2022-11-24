precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform float u_Phase;

vec2 getGradient(vec2 pos, float d) {
    vec4 cx0 = texture2D(u_Tex0, proj0(vec2(pos.x-d, pos.y)));
    vec4 cx1 = texture2D(u_Tex0, proj0(vec2(pos.x+d, pos.y)));
    vec4 cy0 = texture2D(u_Tex0, proj0(vec2(pos.x, pos.y-d)));
    vec4 cy1 = texture2D(u_Tex0, proj0(vec2(pos.x, pos.y+d)));
    return vec2((length(cx1)-length(cx0))/(2.0*d), (length(cy1)-length(cy0))/(2.0*d));
}

float colDist(vec4 a, vec4 b) {
    return abs(a.r-b.r) + abs(a.g-b.g) + abs(a.b-b.b);
}

vec2 getClosest(vec2 pos, float d) {
    vec4 c = texture2D(u_Tex0, proj0(pos));
    vec4 cx0 = texture2D(u_Tex0, proj0(vec2(pos.x-d, pos.y)));
    vec4 cx1 = texture2D(u_Tex0, proj0(vec2(pos.x+d, pos.y)));
    vec4 cy0 = texture2D(u_Tex0, proj0(vec2(pos.x, pos.y-d)));
    vec4 cy1 = texture2D(u_Tex0, proj0(vec2(pos.x, pos.y+d)));
    float dx0 = colDist(cx0, c);
    float dx1 = colDist(cx1, c);
    float dy0 = colDist(cy0, c);
    float dy1 = colDist(cy1, c);
    if (dx0<dx1 && dx0<dy0 && dx0<dy1) return vec2(-d, 0.0);
    else if (dx1<dy0 && dx1<dy1) return vec2(d, 0.0);
    else if (dy0<dy1) return vec2(0.0, -d);
    else return vec2(0.0, d);
}

vec2 getFurthest(vec2 pos, float d) {
    vec4 c = texture2D(u_Tex0, proj0(pos));
    vec4 cx0 = texture2D(u_Tex0, proj0(vec2(pos.x-d, pos.y)));
    vec4 cx1 = texture2D(u_Tex0, proj0(vec2(pos.x+d, pos.y)));
    vec4 cy0 = texture2D(u_Tex0, proj0(vec2(pos.x, pos.y-d)));
    vec4 cy1 = texture2D(u_Tex0, proj0(vec2(pos.x, pos.y+d)));
    float dx0 = colDist(cx0, c);
    float dx1 = colDist(cx1, c);
    float dy0 = colDist(cy0, c);
    float dy1 = colDist(cy1, c);
    if (dx0>dx1 && dx0>dy0 && dx0>dy1) return vec2(-d, 0.0);
    else if (dx1>dy0 && dx1>dy1) return vec2(d, 0.0);
    else if (dy0>dy1) return vec2(0.0, -d);
    else return vec2(0.0, d);
}

vec4 descent0(vec2 pos, vec2 outPos) {
    int N = int(abs(u_Intensity)*u_Tex0Dim.y*0.005);
    float delta = 1.0/u_Tex0Dim.y * sign(u_Intensity);
    vec4 total = texture2D(u_Tex0, proj0(pos));
    for(int i=0; i<N; ++i) {
        vec2 grad = getGradient(pos, delta*(1.0+10.0*u_Phase));
        if (grad.x==0.0 && grad.y==0.0) return total/float(i+1);//break;
        pos += delta * normalize(grad); //vec2(grad.y, grad.x));
//        pos += delta * normalize(vec2(grad.y, grad.x));
        total += texture2D(u_Tex0, proj0(pos));
    }
    return total/float(N+1);
//    return texture2D(u_Tex0, proj0(pos));
}

vec4 descent1(vec2 pos, vec2 outPos) {
    int N = int(abs(u_Intensity)*u_Tex0Dim.y*0.005);
    float delta = 1.0/u_Tex0Dim.y * sign(u_Intensity);
    vec4 total = texture2D(u_Tex0, proj0(pos));
    vec2 grad = getGradient(pos, delta*(1.0+10.0*u_Phase));
    if (grad.x==0.0 && grad.y==0.0) return total;
    grad = normalize(grad);
    for(int i=0; i<N; ++i) {
        grad = normalize(grad + 0.5*normalize(getGradient(pos, delta*(1.0+10.0*u_Phase))));
        pos += delta * grad;
//        pos += delta * vec2(grad.y, grad.x);
        total += texture2D(u_Tex0, proj0(pos));
    }
    return total/float(N+1);
//    return texture2D(u_Tex0, proj0(pos));
}

vec4 descent(vec2 pos, vec2 outPos) {
    int N = int(abs(u_Intensity)*u_Tex0Dim.y*0.005);
    float delta = 1.0/u_Tex0Dim.y * sign(u_Intensity);
    vec4 total = texture2D(u_Tex0, proj0(pos));
    vec2 v = getClosest(pos, delta*(1.0+10.0*u_Phase));
    for(int i=0; i<N; ++i) {
//        vec2 d = getClosest(pos, delta*(1.0+10.0*u_Phase));
        vec2 d = getFurthest(pos, delta*(1.0+10.0*u_Phase));
        v = (5.0*v+d)/6.0;
        pos += v;
//        pos += delta * vec2(grad.y, grad.x);
        total += texture2D(u_Tex0, proj0(pos));
    }
    return total/float(N+1);
//    return texture2D(u_Tex0, proj0(pos));
}


#include mainWithOutPos(descent)
