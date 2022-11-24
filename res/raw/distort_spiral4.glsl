precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Count;
uniform float u_Intensity;
uniform float u_Distortion;
uniform float u_Ratio;
uniform float u_Shadows;
uniform mat3 u_InverseModelTransform;
uniform float u_Phase;
uniform int u_Mirror;



vec4 spiral(vec2 pos, vec2 outPos) {
    vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;

    float d = length(u);

    float intensity = getMaskedParameter(u_Intensity, outPos);
    float p = intensity > 0.0 ? 1.0/(1.0+intensity*0.1) : 1.0+pow(-intensity, 0.75);

    float angle = getVecAngle(u, d);

    float phase = u_Phase;
    float widthAngle = M_PI/4.0;

    if (u_Mirror==1) {
        angle = 2.0*(angle + phase);
        angle = fmod(angle, M_4PI);
        if (angle > M_2PI) { angle = M_4PI-angle; }
    }
    else {
        angle = angle + phase;
        angle = fmod(angle, M_2PI);
    }

    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    float scale360 = 1000.0/(u_Intensity*u_Intensity);
    float a = angle/M_2PI;
    float s = pow(scale360, a);
    float dd = log(d*s) / log(scale360);
    float ddd = fmod(dd, 1.0);
    vec2 coord = mix(ddd, exp(ddd)/exp(1.0), 1.0-u_Distortion*0.01) * vec2(cos(angle), sin(angle));

    //float shadowing = (u_Shadows==0.0 ? 1.0 : (u_Shadows<0.0 ? 1.0/pow(ddd, u_Shadows*0.02) : pow(ddd, u_Shadows*0.02)));

    //float winding = dd-ddd - a;
    //float shadowing = u_Shadows==0.0 ? 1.0 : min(1.0, 1.0 + winding*u_Shadows*0.01);

    float winding = dd-ddd - a;
    vec2 scoord = coord - u_Shadows*0.01*vec2(1.0, 1.0) * mix(1.0, pow(scale360, -winding), u_Shadows*0.001);
    float ds = length(scoord);
    float shadowing = ds>1.0 ? mix(1.0, max(0.0, 6.0-5.0*ds), 0.5+u_Shadows*0.005): 1.0;

    return texture2D(u_Tex0, proj0(coord)) * vec4(shadowing, shadowing, shadowing, 1.0);
}


#include mainWithOutPos(spiral)
