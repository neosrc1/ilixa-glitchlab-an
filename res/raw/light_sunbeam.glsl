precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math

uniform float u_Intensity;
uniform vec4 u_Color1;
uniform float u_Dampening;
uniform float u_Normalize;

float getValue(vec2 p) {
    vec4 c = texture2D(u_Tex0, proj0(p));
    return (c.r+c.g+c.b)/3.0;
}

vec4 sunbeam(vec2 uv, vec2 outPos) {
    vec4 inc = texture2D(u_Tex0, proj0(uv));

    vec2 pos = (u_ModelTransform * vec3(0.0, 0.0, 1.0)).xy;
    float radius = length(u_ModelTransform[0].xy);
    float strongRadius = radius * (1.0 - u_Dampening*u_Dampening*0.0001);
    float step = 0.001;
    vec2 dir = normalize(uv-pos);
    float k = 1.0;
    float dist = length(pos-uv);
    for(float d = 0.0; d<min(radius, dist); d+=step) {
        vec2 p = pos + dir*d;
        float damp = smoothstep(strongRadius*0.25, strongRadius, d);
        float v = mix(1.0, getValue(p), damp);
        //k += 0.001*v;
        k = min(k, max(0.0, v*v));
        //k = min(k, pow(max(0.0, v-d), 2.0));
        //k = min(k, max(0.0, v-d));
    }
    k = k*u_Intensity*0.1;
    vec3 light = k*u_Color1.rgb;

    float value = (inc.r+inc.g+inc.b)/3.0;
    /*float reduce = mix(1.0, smoothstep(1.0, 0.0, value), u_Normalize*0.01);
    return inc + reduce*vec4(light, 0.0);*/
    //float reduce = mix(1.0, 1.0/(1.0+k*u_Color1.a), u_Normalize*0.1);
    float alpha = mix(smoothstep(1.0, 0.0, value), 1.0, u_Color1.a);
    float reduce = mix(1.0, 1.0/(1.0+u_Intensity*0.1), u_Normalize*0.01);
    //return (inc + vec4(light, 0.0))*vec4(vec3(reduce), 1.0);
    return vec4((inc.rgb+alpha*light)*reduce, inc.a);


}

#include mainWithOutPos(sunbeam)
