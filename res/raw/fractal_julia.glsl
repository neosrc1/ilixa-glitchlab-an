precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include perspective

uniform vec2 u_Offset;
uniform int u_Iterations;
uniform int u_Count;
uniform float u_Intensity;



vec4 julia(vec2 pos, vec2 outPos) {

    vec2 z = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;

    vec2 t = u_Offset;

    vec2 prev = t;

    int iter = 0;
    float d2 = 0.0;

    while (iter < u_Iterations) {
        ++iter;
        prev = z;
        z.x = prev.x*prev.x - prev.y*prev.y + t.x;
        z.y = 2.0*prev.x*prev.y + t.y;
        d2 = dot(z, z);
//        avg+=z;
        if (d2 > 4.0) {
            break;
        }
    }

    float angle = 0.0;
    float d = sqrt(d2);

    angle = abs(getVecAngle(z, d));

    float tx = (2.0*angle/M_PI - 1.0) * float(u_Count);
    float intensity = getMaskedParameter(u_Intensity, outPos);
    float step = intensity * 4.0 * float(iter)/float(u_Iterations);
    vec2 s = vec2(tx, pow(d<2.0?2.0-d:(d-2.0), 0.5)  - 1.0 + step);


    return texture2D(u_Tex0, proj0(s));

}


#include mainWithOutPos(julia)
