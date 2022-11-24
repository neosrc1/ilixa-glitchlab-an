precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include hsl
#include tex(1)

uniform float u_Intensity;
uniform float u_Dispersion;

float shift1(vec2 p, float k) {
    return k*
        (1.0+sin(0.54*p.y)) * sin(4.0*sin(0.98*p.y)*p.y)
        + (0.5+0.5*cos(1.54*p.y)) * cos(9.0*cos(3.75*p.y)*p.y)
        + (0.25+0.25*cos(3.421*p.y)) * cos(18.0*cos(8.5*p.y)*p.y);
}

vec4 getRGBWeights(float w) {
    return vec4(
        max(0.0, -w),
        max(0.0, 1.0-abs(w)),
        max(0.0, w),
        1.0
    );
}

vec4 offset(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    float intensity = getMaskedParameter(u_Intensity, outPos);
    intensity *= abs(intensity)*0.01;
    vec2 shifted = pos + 0.001*vec2(shift1(u, intensity), 0.0);
//    float disp = (abs(outPos.x)-0.4)/0.6 * u_Dispersion*0.001;
    float disp = pow(abs(outPos.x), 1.5) * u_Dispersion*0.2;
    if (u_Dispersion>0.0 && disp>0.0) {
        float weights = 0.0;
        vec4 total = vec4(0.0, 0.0, 0.0, 0.0);;
        vec4 totalW = vec4(0.0, 0.0, 0.0, 0.0);
        float N = 50.0;
        float a = 1.0;
        if (u_Tex1Transform[2][2]==0.0) {
            for(float i=-N; i<=N; ++i) {
//                vec4 mul = HSLtoRGB(vec4(i/N*180.0, 1.0, 0.5, 1.0));
                vec4 mul = getRGBWeights(i/N);
                totalW += mul;
//                vec4 col = texture2D(u_Tex0, proj0(shifted + vec2(disp*i/N, 0.0)));
                vec4 col = texture2D(u_Tex0, proj0(mix(pos, shifted, 1.0+disp*i/N)));
                if (i==0.0) a = col.a;
                total += mul*col;
                weights += (mul.r+mul.g+mul.b)/3.0;
            }
        }
        else {
            float ratio = u_Tex1Dim.x/u_Tex1Dim.y;
            for(float i=-N; i<=N; ++i) {
                vec4 mul = texture2D(u_Tex1, proj1(vec2(ratio*i/N, 0.0)));
                totalW += mul;
//                vec4 col = texture2D(u_Tex0, proj0(shifted + vec2(disp*i/N, 0.0)));
                vec4 col = texture2D(u_Tex0, proj0(mix(pos, shifted, 1.0+disp*i/N)));
                if (i==0.0) a = col.a;
                total += mul*col;
                weights += (mul.r+mul.g+mul.b)/3.0;

//                                vec4 mul = texture2D(u_Tex1, proj1(vec2(ratio*i/N, 0.0)));
//                vec4 col = fmod((shifted + vec2(disp*i/N, 0.0)).x*20.0*N, 2.0*N)<1.0 ? vec4(2.0*N, 2.0*N, 2.0*N, 1.0) : vec4(0.0, 0.0, 0.0, 1.0); //texture2D(u_Tex0, proj0(shifted + vec2(disp*i/N, 0.0)));
//                if (i==0.0) a = col.a;
//                total += mul*col;
//                weights += (mul.r+mul.g+mul.b)/3.0;
            }
        }
        return vec4(total.rgb/totalW.rgb, a);
    }
    return texture2D(u_Tex0, proj0(shifted));
}

#include mainWithOutPos(offset)
