precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include perspective
#include random
#include locuswithcolor_nodep

uniform float u_Intensity;
uniform float u_Count;
uniform float u_Regularity;
uniform float u_Roundedness;
uniform mat3 u_Tex00Transform;

float displaceAngle(float angle, float maxDisplacement) {
    return angle + maxDisplacement*(rand(angle)-0.5);
}



vec2 reflect(float d, float sourceAngle, float alpha, float halfAlpha, float halfRoundedAngle) {
    if (sourceAngle > halfAlpha) sourceAngle = alpha-sourceAngle;

    float cornerAngle = halfAlpha - halfRoundedAngle;
    if (halfRoundedAngle==0.0 || sourceAngle<=cornerAngle) {
        return d * vec2(cos(sourceAngle), sin(sourceAngle));
    }
    else {
//        return vec2(0, 0);
//        float d = sin(cornerAngle);
//        vec2 cornerCenter = vec2(d, d);
//        return d * (vec2(cos(cornerAngle), sin(cornerAngle)) + vec2(0.0, sourceAngle-cornerAngle));

        if (cornerAngle==0.0) cornerAngle = 0.001; // hack because I can't figure out the math in this pathological case

        float x = d*cos(sourceAngle);
        float y = d*sin(sourceAngle);
//
        float cha = cos(halfAlpha);
        float sha = sin(halfAlpha);
        float cca = cos(cornerAngle);
        float sca = sin(cornerAngle);

        float A = ((sha/sca*cca-cha)*(sha/sca*cca-cha) - 1.0);
        float B = 2.0*(cha*x + sha*y);
        float C = -(x*x + y*y);
        float delta2 = B*B-4.0*A*C;
        if (delta2<0.0) {
            return vec2(x, y);
        }
        float l = (-B + sqrt(delta2)) / (2.0*A);
        float l2 = (-B - sqrt(delta2)) / (2.0*A);
        float cx = l * cha;
        float cy = l * sha;
        float k = l*sha/sca;

        float Xp = k*cca;
        float Yp = k*sca;
        float R = Xp-cx;

        return vec2(Xp, Yp + R*(sourceAngle-cornerAngle));

    }
}

vec2 proj00(vec2 coord) {
    return vec2(u_Tex00Transform * vec3(coord, 1.0));
}

vec4 kaleidoscope(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;

    float d = length(u);
    float sourceAngle = 0.0;

    float variability = (100.0 - u_Regularity)/100.0;
    float halfAlpha;
    float alpha;
    if (d > 0.0) {
        float ang = getVecAngle(u);
        if (ang<0.0) ang += M_2PI;

        if (variability==20.0) {
            halfAlpha = M_PI/u_Count;
            alpha = halfAlpha * 2.0;
            sourceAngle = fmod(ang, alpha);

//            if (sourceAngle > halfAlpha) sourceAngle = alpha-sourceAngle;
        }
        else {
            float maxDisplacement = M_4PI/u_Count;
            float spikeAngle1 = 0.0;
            float spikeAngle2 = displaceAngle(M_2PI/u_Count, variability*maxDisplacement);

            int spikeCount = int(ceil(u_Count));
            for(int i=0; i<spikeCount; ++i) {
                if ((i==spikeCount-1) || (ang <= spikeAngle2)) {
                    alpha = spikeAngle2 - spikeAngle1;
                    halfAlpha = alpha/2.0;
                    sourceAngle = ang - spikeAngle1;
//                    if (sourceAngle > halfAlpha) sourceAngle = alpha-sourceAngle;
                    break;
                }
                else {
                    spikeAngle1 = spikeAngle2;
                    spikeAngle2 = float(i+2) * M_2PI/u_Count;
                    if (i!=spikeCount-2)
                        spikeAngle2 = displaceAngle(spikeAngle2, variability*maxDisplacement);
                }
            }
        }
    }

//    vec2 coord = d * vec2(cos(sourceAngle), sin(sourceAngle));
    float halfRoundedAngle = halfAlpha * u_Roundedness*0.01;
    vec2 coord = reflect(d, sourceAngle, alpha, halfAlpha, halfRoundedAngle);

    vec4 col = texture2D(u_Tex0, proj00(pos));
    vec4 kCol = texture2D(u_Tex0, proj0(coord));
    return mix(col, kCol, getLocus(pos, col, kCol));

//    float intensity = getMaskedParameter(u_Intensity, outPos)*0.01;
//    float colDist = length(col.rgb-kCol.rgb);
//    return intensity>=0.0 ? (colDist<intensity*1.72 ? kCol : col) : (colDist>(1.0+intensity)*1.72 ? kCol : col);

}

#include mainWithOutPos(kaleidoscope)
