precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Intensity;
uniform float u_RadiusVariability;
uniform float u_Variability;
uniform float u_Balance;
uniform float u_Perturbation;


//vec2 getRandomDelta(float i, float j) {
//    float base= fmod((i+4531.0)*(j+1071.0), 23454.0);
//    vec2 delta;
//    //delta.x = (((base+i*i) * 221778323 + (i>>6)) % 10000) * 0.0001f - 0.5f;
//    //delta.y = (((base-j*j) * 316541237 + (j>>6)) % 10000) * 0.0001f - 0.5f;
//
//    delta.x = fmod((base+i*i) * 3111.0 /*- fmod(i*17733.0, 10000.0)*/, 10000.0) * 0.0001 - 0.5;
//    delta.y = fmod((base-j*j) * 2341.0, 10000.0) * 0.0001 - 0.5;
//
////    delta.x = fmod(float(i), 10.0) * 0.1 - 0.5;
////    delta.y = fmod(float(j), 10.0) * 0.1 - 0.5;
////    delta.x = fmod(base+i*i, 10.0) * 0.1 - 0.5;
////    delta.y = fmod(base-j*j, 10.0) * 0.1 - 0.5;
//    return delta;
//}



vec4 multiwhirl(vec2 pos, vec2 outPos, float scale, float radiusVariability, float variability, float balance, float intensity, float perturbation) {

    vec2 t = (u_ModelTransform * vec3(pos, 1.0)).xy; //transform(pos, center, scale);

    if (perturbation > 0.0) {
        t = perlinDisplace(t, 3, perturbation*0.04);
    }

    float ci = floor(t.x);
    float cj = floor(t.y);

    float k = 0.0;

    vec2 displacement = vec2(0.0, 0.0);

    for(int j = -2; j <= 2; ++j) {
        for(int i = -2; i <= 2; ++i) {
            vec2 center = vec2(float(i)+ci, float(j)+cj);
            vec2 delta = rand2rel(center);
            float radiusModifier = max(0.01, 1.0 + (delta.x * radiusVariability *0.01));
            center += vec2(0.5, 0.5) + delta*variability*0.01;
            vec2 d = t - center;
            k = length(d);

            float threshold = radiusModifier*0.75;
            if (k < threshold) {
                k /= threshold;

                float bal = (-balance+100.0)*0.005;
                if (bal != 0.5) {
                    if (bal==1.0 || k < bal) {
                        float ratio2 = k/bal;
                        k = 0.5 * ratio2;
                    }
                    else {
                        float ratio2 = (k-bal)/(1.0-bal);
                        k = 0.5 * (1.0-ratio2);
                    }
                }

                float intensity2 = getMaskedParameter(intensity, outPos);

                float dangle = intensity2 * delta.x * 0.1 * (1.0-cos(k*2.0*M_PI));
                float ca = cos(dangle);
                float sa = sin(dangle);
                vec2 rotated = vec2(ca*d.x - sa*d.y, ca*d.y + sa*d.x);
                displacement += (rotated - d) / scale;
            }
        }
    }


    return texture2D(u_Tex0, proj0(pos + displacement));

}


void main()
{
    float scale = sqrt(u_ModelTransform[0][0]*u_ModelTransform[0][0] + u_ModelTransform[0][1]*u_ModelTransform[0][1]);

    vec4 outc;

    if (u_Antialias==4) {
        vec2 outPos00 = (v_OutCoordinate * u_Tex0Dim + vec2(-0.333, -0.333)) / u_Tex0Dim;
        vec2 outPos10 = (v_OutCoordinate * u_Tex0Dim + vec2(0.333, -0.333)) / u_Tex0Dim;
        vec2 outPos01 = (v_OutCoordinate * u_Tex0Dim + vec2(-0.333, 0.333)) / u_Tex0Dim;
        vec2 outPos11 = (v_OutCoordinate * u_Tex0Dim + vec2(0.333, 0.333)) / u_Tex0Dim;

        vec2 pos00 = (u_ViewTransform * vec3(outPos00, 1.0)).xy;
        vec2 pos10 = (u_ViewTransform * vec3(outPos10, 1.0)).xy;
        vec2 pos01 = (u_ViewTransform * vec3(outPos01, 1.0)).xy;
        vec2 pos11 = (u_ViewTransform * vec3(outPos11, 1.0)).xy;
        outc = (multiwhirl(pos00, outPos00, scale, u_RadiusVariability, u_Variability, u_Balance, u_Intensity, u_Perturbation) +
            multiwhirl(pos10, outPos10, scale, u_RadiusVariability, u_Variability, u_Balance, u_Intensity, u_Perturbation) +
            multiwhirl(pos01, outPos01, scale, u_RadiusVariability, u_Variability, u_Balance, u_Intensity, u_Perturbation) +
            multiwhirl(pos11, outPos11, scale, u_RadiusVariability, u_Variability, u_Balance, u_Intensity, u_Perturbation) ) * 0.25;
    }
    else {
        vec2 pos = (u_ViewTransform * vec3(v_OutCoordinate, 1.0)).xy;
        outc = multiwhirl(pos, v_OutCoordinate, scale, u_RadiusVariability, u_Variability, u_Balance, u_Intensity, u_Perturbation);
    }

//    gl_FragColor = multiwhirl(v_OutCoordinate, u_Offset, u_Scale, 100.0, 100.0, 100.0, 100.0);



    gl_FragColor = blend(outc, v_OutCoordinate);


//    gl_FragColor = (ripples(pos00, center, radius) + ripples(pos10, center, radius) + ripples(pos01, center, radius) + ripples(pos11, center, radius)) * 0.25;
}
