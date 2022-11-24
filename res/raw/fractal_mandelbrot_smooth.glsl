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
uniform float u_Power;
uniform float u_Offset1d;
uniform float u_Julianess;
uniform vec4 u_Color1;
uniform vec4 u_Color2;


vec4 mandelbrot(vec2 pos, vec2 outPos) {

    float cj = cos(u_Julianess * M_PI*0.005);
    float sj = sin(u_Julianess * M_PI*0.005);

    vec2 t = (u_ModelTransform * vec3(cj * perspective(pos), 1.0)).xy;

    vec2 z0 = (mat2(u_ModelTransform) * (sj * perspective(pos))) + u_Offset;
    vec2 z = z0;

    vec2 prev = t;

    int iter = 0;
    float d2 = 0.0;
    bool outside = true;

//    float power = getMaskedParameter(u_Intensity, outPos)*0.05+1.0;

    if (u_Power == 2.0) {
        while (iter < u_Iterations) {
            ++iter;
            prev = z;
            z.x = prev.x*prev.x - prev.y*prev.y + t.x;
            z.y = 2.0*prev.x*prev.y + t.y;
            d2 = dot(z, z);
            if (d2 > 400000000.0) {
                outside = false;
                break;
            }
        }
    }
    else if (u_Power == 3.0) {
        while (iter < u_Iterations) {
            ++iter;
            prev = z;
            z.x = prev.x*prev.x*prev.x - 3.0*prev.y*prev.y*prev.x + t.x;
            z.y = -prev.y*prev.y*prev.y + 3.0*prev.x*prev.x*prev.y + t.y;
            d2 = dot(z, z);
            if (d2 > 400000000.0) {
                outside = false;
                break;
            }
        }
    }
    else {
        float d = length(z);

        while (iter < u_Iterations) {
            ++iter;
            prev = z;
            float angle = getVecAngle(prev, d);
            //if (angle<0.0) angle+=M_2PI;

            float dp = pow(d, u_Power);
            z.x = dp*cos(u_Power*angle) + t.x;
            z.y = dp*sin(u_Power*angle) + t.y;

            d = length(z);
            if (d > 20000.0) {
                outside = false;
                break;
            }
        }

        d2 = d*d;
    }


    float angle = 0.0;
    float d = sqrt(d2);

    angle = cj*getVecAngle(t) + sj*getVecAngle(z0);
    float ratio = u_Tex0Dim.x / u_Tex0Dim.y;

    float tx = (angle/M_PI - 1.0);// * float(u_Count);
    float intensity = getMaskedParameter(u_Intensity, outPos);
    float step = u_Offset1d * 4.0 * float(iter)/float(u_Iterations);
    float ty = 1.0 + float(iter) - log(log(d))/log(u_Power);
    if (u_Offset1d!=0.0) ty = pow(ty, pow(1.05, -u_Offset1d));
    vec2 s = vec2(tx, ty);


    vec4 texCol = texture2D(u_Tex0, vec2(s.x+u_Tex0Transform[2][0], proj0(s).y));
    vec4 inoutCol = outside ? u_Color1 : u_Color2;
    return vec4(mix(texCol.rgb, inoutCol.rgb, inoutCol.a), texCol.a);

}

#include mainWithOutPos(mandelbrot)
