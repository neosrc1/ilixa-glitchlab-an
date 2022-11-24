precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform float u_Balance;

vec2 getGradient(vec2 pos, float d) {
    vec4 cx0 = texture2D(u_Tex0, proj0(vec2(pos.x-d, pos.y)));
    vec4 cx1 = texture2D(u_Tex0, proj0(vec2(pos.x+d, pos.y)));
    vec4 cy0 = texture2D(u_Tex0, proj0(vec2(pos.x, pos.y-d)));
    vec4 cy1 = texture2D(u_Tex0, proj0(vec2(pos.x, pos.y+d)));
    return vec2((length(cx1)-length(cx0))/(2.0*d), (length(cy1)-length(cy0))/(2.0*d));
}

vec4 descent(vec2 pos, vec2 outPos) {
    float intensity = u_Intensity;
//    int N = int(abs(u_Intensity)*u_Tex0Dim.y*0.005);
//    float delta = 1.0/u_Tex0Dim.y * sign(u_Intensity);
    int N = int(abs(intensity)*5.0);
    float delta = 0.001 * sign(intensity);

    vec4 total = texture2D(u_Tex0, proj0(pos));
//    vec2 grad = getGradient(pos, delta*(1.0+10.0*u_Phase));
    vec2 grad = getGradient(pos, u_Balance*0.001);
    if (grad.x==0.0 && grad.y==0.0) return total;
    grad = normalize(grad);
    for(int i=0; i<N; ++i) {
//        grad = normalize(grad + 0.5*normalize(getGradient(pos, delta*(1.0+10.0*u_Phase))));
        vec2 g1 = getGradient(pos, u_Balance*0.001);
        if (g1.x==0.0 && g1.y==0.0) return total/float(i+1);
        vec2 g2 = grad + 0.5*normalize(g1);
        if (g2.x==0.0 && g2.y==0.0) return total/float(i+1);
        grad = normalize(g2);
//        grad = normalize(grad + 0.5*normalize(getGradient(pos, u_Balance*0.001)));
        pos += sign(u_Balance) * delta * grad;

        if (length(pos)>3.0) return vec4(1.0, 0.0, 0.0, 1.0);
        else if (length(pos)<0.0001) return vec4(0.0, 1.0, 0.0, 1.0);

//        pos += delta * vec2(grad.y, grad.x);
        total += texture2D(u_Tex0, proj0(pos));
    }
    return total/float(N+1);
//    return texture2D(u_Tex0, proj0(pos));
}


#include mainWithOutPos(descent)
