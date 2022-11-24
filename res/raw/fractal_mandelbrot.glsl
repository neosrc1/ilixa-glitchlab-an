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

/*
vec4 mandelbrot(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;

    vec2 z = u_Offset;

    vec2 prev = t;

    int iter = 0;
    float d2 = 0.0;

    while (iter < u_Iterations) {
        ++iter;
        prev = z;
        z.x = prev.x*prev.x - prev.y*prev.y + t.x;
        z.y = 2.0*prev.x*prev.y + t.y;
        d2 = dot(z, z);
        if (d2 > 4.0) {
            break;
        }
    }

    //if (iter == u_Iterations) return texture2D(u_Tex0, proj0(z)); // no polar projection in the set itself

    float angle = 0.0;
    float d = sqrt(d2);

    angle = abs(getVecAngle(z, d));

    float tx = (2.0*angle/M_PI - 1.0) * float(u_Count);
    vec2 s = vec2(tx, pow(d<2.0?2.0-d:(d-2.0), 0.5) - 1.0);


    return texture2D(u_Tex0, proj0(s));

}

vec4 mandelbrot2(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;

    vec2 z = u_Offset;

    vec2 prev = t;

    int iter = 0;
    float d2 = 0.0;

    while (iter < u_Iterations) {
        ++iter;
        prev = z;
        z.x = prev.x*prev.x - prev.y*prev.y + t.x;
        z.y = 2.0*prev.x*prev.y + t.y;
    }

    return texture2D(u_Tex0, proj0(z));

}

// fine texture around the set followed by re-uniformisation - interesting outward structures with offset
vec4 mandelbrot3(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;

    vec2 z = u_Offset;

    vec2 prev = t;

    int iter = 0;
    float d2 = 0.0;

    while (iter < u_Iterations) {
        ++iter;
        prev = z;
        z.x = prev.x*prev.x - prev.y*prev.y + t.x;
        z.y = 2.0*prev.x*prev.y + t.y;

        float len = length(z);
        if (len>2.0) z = mix(t, z, 2.0/len);
//        if (len>2.0) z = (t + (len-2.0)*z)/(len-1.0); // horizontal feature version but rapid out of bounds
    }

    return texture2D(u_Tex0, proj0(z));

}

// strong canditate for inclusion
vec4 mandelbrot4(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;

    vec2 z = u_Offset;

    vec2 prev = t;

    int iter = 0;
    float d2 = 0.0;

    while (iter < u_Iterations) {
        ++iter;
        prev = z;
//        z.x = prev.x*prev.x - prev.y*prev.y + t.x;
//        z.y = 2.0*prev.x*prev.y + t.y;

        z.x = prev.x*prev.x*prev.x - 3.0*prev.y*prev.y*prev.x + t.x;
        z.y = -prev.y*prev.y*prev.y + 3.0*prev.x*prev.x*prev.y + t.y;


        float len = length(z);
//        if (len>2.0) z /= sqrt(len-1.0);
//        if (len>2.0) z = (z + (len-2.0)*t)/(len-1.0); // microchip
//        if (len>2.0) { float k = (len-2.0)*(len-2.0); z = (z + k*t)/(k+1.0); } // cool overlaping features
//        float k = len*len; z = (z + k*t)/(k+1.0); // not fractal but interesting
        float intensity = getMaskedParameter(u_Intensity, outPos);
        float p = intensity*intensity*intensity*intensity*intensity * (4.0/pow(50.0, 5.0)); float k = len*len*p; z = (z + k*t)/(k+1.0);
    }

//    float len = length(z);
//    if (len>0.0) z /= len;

    return texture2D(u_Tex0, proj0(z));

}

vec4 mandelbrot5(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;

    vec2 z = u_Offset;

    vec2 prev = t;

    int iter = 0;
    float d2 = 0.0;

//    vec2 avg = prev;

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

//    if (d2>4.0 && d2<6.0) {
//        z = (z*(d2-4.0) + prev*(6.0-d2)) / 2.0;
//        d2 = dot(z, z);
//    }



//    z = avg / float(iter+1);
//    d2 = dot(z, z);


    float angle = 0.0;
    float d = sqrt(d2);

    angle = abs(getVecAngle(z, d));

    float tx = (2.0*angle/M_PI - 1.0) * float(u_Count);
    float intensity = getMaskedParameter(u_Intensity, outPos);
    float step = intensity * 4.0 * float(iter)/float(u_Iterations);
    vec2 s = vec2(tx, pow(d<2.0?2.0-d:(d-2.0), 0.5)  - 1.0 + step);


    return texture2D(u_Tex0, proj0(s));

}


vec4 mandelbrot6(vec2 pos, vec2 outPos) {

    vec2 t = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;

    vec2 z = u_Offset;

    vec2 prev = t;

    int iter = 0;
    float d2 = 0.0;

    vec2 avg = prev;

    while (iter < u_Iterations) {
        ++iter;
        prev = z;
        z.x = prev.x*prev.x - prev.y*prev.y + t.x;
        z.y = 2.0*prev.x*prev.y + t.y;

        // interesting overlaping features (though not very complex)
//        z.x = prev.x*prev.x*prev.y - prev.y*prev.x*prev.y + t.x;
//        z.y = 2.0*prev.x*prev.y + t.y;

// cube mandelbrot
//        z.x = prev.x*prev.x*prev.x - 3.0*prev.y*prev.y*prev.x + t.x;
//        z.y = -prev.y*prev.y*prev.y + 3.0*prev.x*prev.x*prev.y + t.y;

        avg+=z;

        d2 = dot(z, z);
        if (d2 > 4.0) {
            break;
        }

    }

    if (d2>4.0) {
        z = (z*(d2-4.0) + prev) / (d2-3.0);
        d2 = dot(z, z);
    }

//    z = avg / float(iter+1);
//    d2 = dot(z, z);

    return texture2D(u_Tex0, proj0(z));

}*/

vec4 mandelbrot7(vec2 pos, vec2 outPos) {

    float cj = cos(u_Julianess * M_PI*0.005);
    float sj = sin(u_Julianess * M_PI*0.005);

    vec2 t = (u_ModelTransform * vec3(cj * perspective(pos), 1.0)).xy;

    vec2 z = (mat2(u_ModelTransform) * (sj * perspective(pos))) + u_Offset;

    vec2 prev = t;

    int iter = 0;
    float d2 = 0.0;

//    float power = getMaskedParameter(u_Intensity, outPos)*0.05+1.0;

    if (u_Power == 2.0) {
        while (iter < u_Iterations) {
            ++iter;
            prev = z;
            z.x = prev.x*prev.x - prev.y*prev.y + t.x;
            z.y = 2.0*prev.x*prev.y + t.y;
            d2 = dot(z, z);
            if (d2 > 4.0) {
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
            if (d2 > 4.0) {
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
            if (d > 2.0) {
                break;
            }
        }

        d2 = d*d;
    }


    float angle = 0.0;
    float d = sqrt(d2);

    angle = getVecAngle(z, d);

    float tx = (2.0*angle/M_PI - 1.0) * float(u_Count);
    float intensity = getMaskedParameter(u_Intensity, outPos);
    float step = u_Offset1d * 4.0 * float(iter)/float(u_Iterations);
    vec2 s = vec2(tx, pow(d<2.0?2.0-d:(d-2.0), 0.5)  - 1.0 + step);


    return texture2D(u_Tex0, proj0(s));

}


//#include mainWithOutPos(mandelbrot5)
#include mainWithOutPos(mandelbrot7)
