precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include perspective

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform int u_Count; // levels
uniform float u_Seed;
uniform float u_Roundedness;
uniform float u_Thickness;
uniform float u_Regularity;
uniform float u_Distribution;

float hash2(vec2 id) {
	float a = fract(dot(id+23.23, id.yx*10.2232));
    float b = fract(a + id.x*232.23 - id.y*777.77);
    return fract(a*5.22 + b + a*b*23.77 + 99.9);
}
/*
float hash41(vec2 id, vec2 id2) {
    vec2 ida = min(id, id2);
    vec2 idb = max(id, id2);
	float a = fract(dot(ida+23.23, idb.yx*10.2232) + u_Seed + ((ida==id || ida==id2) ? 123.32 : -123.55));
    float b = fract(a + ida.x*232.23 - idb.y*777.77);
    return fract(a*5.22 + b + a*b*23.77 + 99.9);
}

float hash4(vec2 id, vec2 id2) {
    vec2 ida = min(id, id2);
    vec2 idb = max(id, id2);
	float a = fract(dot(ida+2.0, idb.yx*10.1) + u_Seed + ((ida==id || ida==id2) ? 123.32 : -123.55));
    float b = fract(a + ida.x*232.2 - idb.y*777.05);
    return fract(a*5.01 + b + a*b*23.05 + 99.0);
}*/

float hash4(vec2 id, vec2 id2, float regularity, vec4 vecSeed) {
    vec2 ida = min(id, id2);
    vec2 idb = max(id, id2);
	float a = fract(dot(ida+23.23, idb.yx*10.2232) + ((ida==id || ida==id2) ? 123.32 : -123.55));
    float b = fract(a + ida.x*232.23 - idb.y*777.77);
    float irreg = fract(a*5.22 + b + a*b*23.77 + 99.9);
    float reg = fract(dot(vec4(ida, idb), vecSeed));//ida.x*vec+ida.y*0.2 + idb.x*0.3+idb.y*0.5);
    return mix(irreg, reg, regularity);
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p-a, ba = b-a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    return length(pa - ba*h);
}

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}


vec4 circuit(vec2 pos, vec2 outPos) {
    vec2 uv = (u_ModelTransform * vec3(perspective(pos), 1.0)).xy;

    vec4 vecSeed = vec4(rand2relSeeded(vec2(0.0, 0.0), u_Seed-8.0), rand2relSeeded(vec2(0.5212, 10.0), u_Seed-8.0));
    vec2 rnd = rand2relSeeded(vec2(1.0, 2.0), (u_Seed-8.0)*0.3);
    float density = 0.55 + rnd.x*0.6;
    float diagonals = (1.0-pow(rnd.y+0.5, 10.0))*0.5;

    float D = 1e9;
    for(float Y=-1.0; Y<=1.0; ++Y) {
        for(float X=-1.0; X<=1.0; ++X) {

            vec2 id = floor(uv)+vec2(X, Y);
    		vec2 u = uv-id-0.5;
            float d = 1e9;
            int count = 0;
            vec2 first, second;
            for(float y=-1.0; y<=1.0; ++y) {
                for(float x=-1.0; x<=1.0; ++x) {
                    if (x!=0.0 || y!=0.0) {
                        //bool on = hash41(id, id+vec2(x, y)) < 0.65-0.24*(abs(x)+abs(y));
                        //bool on = hash4(id, id+vec2(x, y), u_Regularity*0.01, vecSeed) < 0.65-0.32*(abs(x)+abs(y));
                        bool on = hash4(id, id+vec2(x, y), u_Regularity*0.01, vecSeed) < density*(1.0-diagonals*(abs(x)+abs(y)));
                        //bool on = hash4(id, id+vec2(x, y)) < 0.4-0.24*(abs(x));
                        //bool on = hash4(id, id+vec2(x, y)) < 0.5;
                        if (count==0) first = vec2(x, y);
                        else if (count==1) second = vec2(x, y);
                        if (on) {
                            ++count;
                            d = min(d, sdSegment(u, vec2(0.0), 0.5*vec2(x, y)));
                        }
                    }
                }
            }
            if (count==1) {
                float l = length(u);
                float cr = rnd.x+0.25>u_Regularity*0.01 ? 0.0025*u_Roundedness*ceil(hash2(id)*2.0)/2.0 : 0.0025*u_Roundedness;
                if (l<cr) d = abs(sdCircle(u, cr));
                else d = min(d, abs(sdCircle(u, cr)));
            }
            else if (count==2 && dot(first, second)==0.0) {
                float cr = 0.005*u_Roundedness;
                vec2 c = cr*(first+second);
                //if (abs(u.x)<cr && abs(u.y)<cr) {
                //if (dot(u, first)<cr && dot(u, second)<cr) {
                if (dot(u-c, -first)>=0.0 && dot(u-c, -second)>=0.0) {
                    float radius = sdSegment(c, vec2(0.0, 0.0), first);
                    d = abs(sdCircle(u-c, radius));
                }
            }

            D = min(D, d);
        }
    }

   	//g = smoothstep(0.05, 0.045, d);
   	float thick = 0.0015*u_Thickness;
   	float k = smoothstep(thick, thick-0.005, D);

    return mix(u_Color1, u_Color2, k);

}

#include mainWithOutPos(circuit)
