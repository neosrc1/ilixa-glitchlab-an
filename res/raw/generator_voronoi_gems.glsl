precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform vec4 u_Color1;
uniform float u_ColorVariability;
uniform float u_Regularity;
uniform float u_Shadows;
uniform float u_Specular;
uniform float u_ColorBleed;
uniform float u_Gamma;

vec2 hash22(vec2 u) {
    return vec2(
    fract(sin(u.x*776.45+u.y*453.24)*45.77),
    fract(sin(u.x*376.45+u.y*853.24)*88.77) );
}
vec2 hash22b(vec2 u) {
    return vec2(
    fract(u.y*0.5),
    fract(0.0) );
}

struct Tile {
    float centerDist;
    vec2 tileId;
    float borderDist;
    vec2 center;
    vec2 borderNormal;
    float secondCenterDist;
    vec2 secondTileId;
};

Tile getTile(vec2 u, float intensity) {
    vec2 b = floor(u+0.5);
    float N = floor(2.0+0.5*abs(intensity));
    float minD = 1e10;
    float minB = 1e10;
    vec2 minId;
    vec2 minC;
    vec2 normal;
    vec2 secId;
    float secD;
    for(float j=b.y-N; j<=b.y+N; ++j) {
        for(float i=b.x-N; i<=b.x+N; ++i) {
            vec2 id = vec2(i, j);
            vec2 c = id + intensity * (hash22(id)-0.5);
            float d = length(u-c);
            if (minD>=d) {
                secId = minId;
                secD = minD;
                minId = id;
                minD = d;
                minC = c;
            }
            else if (secD>=d) {
                secId = id;
                secD = d;
            }
        }
    }
    for(float j=b.y-N; j<=b.y+N; ++j) {
        for(float i=b.x-N; i<=b.x+N; ++i) {
            vec2 id = vec2(i, j);
            if (id!=minId) {
                vec2 c = id + intensity * (hash22(id)-0.5);
                vec2 v = normalize(c-minC);
                float borderDist = length(minC-c)/2.0 - dot(u-minC, v);
                minB = min(borderDist, minB);
                if (minB==borderDist) normal = vec2(-v.x, v.y);
            }
        }
    }

    //vec2 v = normalize(secC-minC);
    //float borderDist = length(minC-secC)/2.0 - dot(u-minC, v);
    return Tile(minD, minId, minB, minC, normal, secD, secId);
}

vec3 color(vec2 id) {
    vec3 delta = u_ColorVariability*0.01 * vec3(hash22(id)-0.5, hash22(id+123.0).x-0.5);
    vec3 rgb = u_Color1.rgb + delta;
    return vec3(clamp(rgb.r, 0.0, 1.0), clamp(rgb.g, 0.0, 1.0), clamp(rgb.b, 0.0, 1.0));
}
/*
vec3 color(vec2 id) {
    return 0.2+0.8*fract(vec3(id.x*2.9, id.y*1.8, id.x*id.y*0.1));
}*/

vec4 gems(vec2 pos, vec2 outPos) {
    vec2 uv = (u_ModelTransform * vec3(pos, 1.0)).xy;

    /*mat4 cell = getTile2(uv, sin(iTime)*1.0);
    float d = cell[0].x;
    float d2 = cell[2].x;
    vec2 id = cell[0].yz;
    vec2 secId = cell[2].yz;
    float b = cell[0].w;
    vec2 normal = cell[1].xy;*/

    Tile cell = getTile(uv, 2.0*(1.0-u_Regularity*0.01));
    float d = cell.centerDist;
    float d2 = cell.secondCenterDist;
    vec2 id = cell.tileId;
    vec2 secId = cell.secondTileId;
    float b = cell.borderDist;
    vec2 normal = cell.borderNormal;

    float s = dot(normal, vec2(0.0, -1.0));
    //float specular = smoothstep(0.4, 1.0, s));
    float light = pow(b, 0.35*pow(1.06, u_Shadows-50.0));
    //if (s>0.0) light *= 1.0 + 2.85*smoothstep(0.8, 1.0, s);

    float plight = 1.0 + 1.5*smoothstep(0.6, 1.0, s);
    float nlight = (1.0-light) * (1.5 + smoothstep(0.25, 1.0, -s));
    light *= mix(1.0, mix(nlight, plight, smoothstep(-0.2, 0.2, s)), u_Specular*0.01);
    //if (s>0.0) light *= plight;//1.0 + 1.5*smoothstep(0.6, 1.0, s); //need a smooth blend into value below around s==0.0
    //else light *= nlight; //= light * (1.0-light) * (1.5 + smoothstep(0.25, 1.0, -s));

    //col = vec3(hash22(id), 0.7) * light; // gems
    //float colorBleed = 0.25*smoothstep(2.0, 1.0, cell[2].x/d);
    float colorBleed = mix(0.0, 0.2*smoothstep(0.0, 0.9, d) + smoothstep(2.0, 1.0, d2/d), u_ColorBleed*0.01);
    vec3 rgb = color(id);
    vec3 col = mix(rgb, color(secId), 1.0*colorBleed) * light; // gems

    float lum = (col.r+col.g+col.b)/3.0;
    if (lum>0.0 && u_Gamma!=0.0) {
        float gammaCorrectedLum = pow(lum, pow(1.02, -u_Gamma));
        col = col * gammaCorrectedLum/lum;
    }
    return vec4(col, 1.0);
}

#include mainWithOutPos(gems)
