precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include perspective
#include random

uniform float u_Blend;
uniform float u_Count;
uniform float u_Variability;
uniform float u_Roundedness;
uniform float u_Seed;


vec2 reflect(float d, float sourceAngle, float alpha, float halfAlpha) {
    if (sourceAngle > halfAlpha) sourceAngle = alpha-sourceAngle;
    return d * vec2(cos(sourceAngle), sin(sourceAngle));
}

vec2 proj0transformed(mat3 t, vec2 coord) {
    return (t * u_Tex0Transform * vec3(coord, 1.0)).xy;
}

vec4 kaleidoscope(vec2 pos, vec2 outPos) {
    float totalWeight = 0.0;
    vec4 totalCol = vec4(0.0, 0.0, 0.0, 0.0);
    vec2 totalCoord = vec2(0.0, 0.0);
    vec4 lightestCol = vec4(0.0, 0.0, 0.0, 1.0);
    float lightestVal = 0.0;

    float N = 1.0;
    for(float j=-N; j<=N; ++j) {
        for(float i=-N; i<=N; ++i) {

            vec2 u = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;
            vec2 id = floor((u+1.0)/2.0) + vec2(i, j);
            vec2 center = id*2.0;// + variability*vec2(rnd3.y, rnd2.y)*3.5;
            u = u-center;

            float d = length(u);
            float weight;
            if (u_Blend==0.0) {
                weight = max(abs(u.x), abs(u.y))<=1.0 ? 1.0 : 0.0;
            }
            else if (u_Blend<15.0) {
                weight = smoothstep(1.0+u_Blend*0.01, 1.0-u_Blend*0.01, max(abs(u.x), abs(u.y)));
            }
            else if (u_Blend<30.0) {
//                float squareWeight = smoothstep(1.0+u_Blend*0.01, 1.0-u_Blend*0.01, max(abs(u.x), abs(u.y)));
//                float circleWeight = smoothstep(1.4+u_Blend*0.01, 1.4-u_Blend*0.01, d);
                float squareWeight = smoothstep(1.0+0.15, 1.0-0.15, max(abs(u.x), abs(u.y)));
                float circleWeight = smoothstep(1.4+0.15, 1.4-0.15, d);
                weight = mix(squareWeight, circleWeight, (u_Blend-15.0)/15.0);
            }
            else {
                float b = mix(0.15, 1.0, (u_Blend-30.0)/70.0);
                weight = smoothstep(1.4+b, 1.4-b, d);
            }

            if (weight>0.0) {
                float sourceAngle = 0.0;

                float halfAlpha;
                float alpha;
                if (d > 0.0) {
                    float ang = getVecAngle(u);
                    if (ang<0.0) ang += M_2PI;

                    halfAlpha = M_PI/u_Count;
                    alpha = halfAlpha * 2.0;
                    sourceAngle = fmod(ang, alpha);
                }

                vec2 coord = reflect(d, sourceAngle, alpha, halfAlpha);
                float angle = 0.0;
                float scale = 1.0;
                vec2 t = vec2(0.0, 0.0);

                if (id.x!=0.0 || id.y!=0.0) {
                    vec2 rnd = rand2relSeeded(id, u_Seed);
                    float variability = u_Variability*0.01;
                    angle = variability*rnd.x*M_PI*2.0;
                    scale = variability*rnd.y*0.2+1.0;
                    t = variability*rnd*2.0;
                    //tr = mat3(scale*cos(angle), scale*sin(angle), 0.0, -scale*sin(angle), scale*cos(angle), 0.0, t.x, t.y, 1.0); // this approach crashes on some devices such as Nexus 7
                }
                vec3 tc = u_Tex0Transform * vec3(coord, 1.0);
                vec2 tcc = vec2(scale*(cos(angle)*tc.x+sin(angle)*tc.y)+t.x, scale*(-sin(angle)*tc.x+cos(angle)*tc.y)+t.y);
                vec4 col = texture2D(u_Tex0, tcc);

                totalCol += weight*col;
                totalWeight += weight;
            }
        }
    }

    return totalCol/totalWeight;

}

#include mainWithOutPos(kaleidoscope)
