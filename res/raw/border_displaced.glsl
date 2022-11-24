precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include tex(1)

uniform float u_Left;
uniform float u_Right;
uniform float u_Top;
uniform float u_Bottom;
uniform vec4 u_Color;
uniform float u_Intensity;
uniform float u_Phase;
uniform float u_Blur;

vec2 displace(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy;

    if (u_Intensity != 0.0) {
        vec4 val = u_Tex1Transform[2][2]==0.0 ? texture2D(u_Tex0, proj0(t)) : texture2D(u_Tex1, proj1(t));
        float intensity = getMaskedParameter(u_Intensity, outPos);
        val.xy -= vec2(0.5, 0.5);
        vec2 t = u_Phase==0.0
            ? val.xy
            : vec2(cos(u_Phase)*val.x-sin(u_Phase)*val.y, cos(u_Phase)*val.y+sin(u_Phase)*val.x);
        float thickness = max(max(u_Left, u_Right), max(u_Bottom, u_Top));
        vec2 displacement = intensity * 0.04 * thickness * t;
        pos += displacement;
    }

    return pos;

}

float border(vec2 pos) {
    float ratio = u_outDim.x / u_outDim.y;

    if (pos.y<-1.0+u_Top*2.0 || pos.y>1.0-u_Bottom*2.0 || pos.x<-ratio+u_Left*2.0 || pos.x>ratio-u_Right*2.0) {
        return 1.0;
    }
    else {
        return 0.0;
    }
}

float blur(vec2 pos, vec2 outPos) {
    float radius = u_Blur*0.0002;
    float step = 2.0/u_Tex0Dim.y;
    int N = int(floor(radius/step));
    float total = 0.0;
    for(int j=-N; j<=N; ++j) {
        for(int i=-N; i<=N; ++i) {
            total += border(displace(pos + vec2(float(i), float(j)) * vec2(step, step), outPos));
        }
    }
    return floor(total/float((2*N+1)*(2*N+1)) + 0.5);
}

vec4 border(vec2 pos, vec2 outPos) {
    float k = u_Blur==0.0 ? border(displace(pos, outPos)) : blur(pos, outPos);
    if (k==1.0) return u_Color;
    else return mix(texture2D(u_Tex0, proj0(pos)), u_Color, k);

}

#include mainWithOutPos(border)
