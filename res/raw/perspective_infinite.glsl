precision highp float;
precision highp int;
#define OOB 999999.99

#include math
#include commonvar
#include commonfun
#include random
#include rand3
#include bkg3d

uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;
uniform float u_Count;
uniform float u_Intensity;
uniform float u_Balance;
uniform float u_Radius;
uniform float u_Variability;
uniform float u_Seed;
uniform int u_Mode;

float sqr(float x) { return x*x; }

vec3 getCenter(vec3 p) {
    if (u_Variability<=0.0) return vec3(0.5, 0.5, 0.5);

    vec3 f = fract(p);
    vec3 m = p-f;
    vec3 disp = rand3relSeeded(m.xy + vec2(m.z, m.z*2.0), u_Seed);
    float amp = max(0.0, 0.5-u_Radius*0.01) * u_Variability*0.01;
    return vec3(0.5, 0.5, 0.5) + disp*amp;
}

float distanceEstimateThingy(vec3 p) {
    p.xyz += 1.000*sin(  2.0*p.yzx );
    p.xyz += 0.500*sin(  4.0*p.yzx );
    p.xyz += 0.150*sin(  8.0*p.yzx );
    p.xyz += 0.050*sin( 16.0*p.yzx );
    return length(p) - 1.5;
}

float distanceEstimateOld(vec3 p) {
    //    vec3 f = vec3(fract(p.xy), p.z);
    //    return length(f-vec3(0.5, 0.5, 0.0)) - 0.5;
    vec3 f = fract(p);
    vec3 center = getCenter(p);
    return length(f-center) - u_Radius*0.01;
}

float distanceEstimate(vec3 p) {
    //    vec3 f = vec3(fract(p.xy), p.z);
    //    return length(f-vec3(0.5, 0.5, 0.0)) - 0.5;
    vec3 id = floor(p);
    if (u_Mode==0) {
        if (id.z!=0.0) return 0.5;
    }
    else if (u_Mode==1) {
        if (id.y!=0.0) return 0.5;
    }
    else if (u_Mode==2) {
        if (id.x!=0.0) return 0.5;
    }
    else if (u_Mode==3) {
        if (fmod(float(id.x+id.y+id.z), 2.0)==0.0) return 0.5;
    }
    else if (u_Mode==4) {
        if (fmod(float(id.x), 2.0)==0.0 || fmod(float(id.y), 2.0)==0.0) return 0.5;
    }
    vec3 f = fract(p);
    vec3 center = getCenter(p);
    return length(f-center) - u_Radius*0.01;
}


float distanceEstimateLake(vec3 p) {
//    vec3 f = vec3(fract(p.xy), p.z);
//    return length(f-vec3(0.5, 0.5, 0.0)) - 0.5;
    float z = fract(p.z);
    return abs(p.y - 0.1 * sin(z*M_2PI));
}

vec3 getNormalThingy(vec3 p) {
    float d = 0.01;
    float d2 = d*2.0;
    return normalize(vec3(
        (distanceEstimate(vec3(p.x-d, p.y, p.z))-distanceEstimate(vec3(p.x+d, p.y, p.z)))/d2,
        (distanceEstimate(vec3(p.x, p.y-d, p.z))-distanceEstimate(vec3(p.x, p.y+d, p.z)))/d2,
        (distanceEstimate(vec3(p.x, p.y, p.z-d))-distanceEstimate(vec3(p.x, p.y, p.z+d)))/d2
        ));
}
vec3 getNormal(vec3 p) {
    vec3 f = fract(p);
    vec3 center = getCenter(p);
    return normalize(f-center);
}
vec3 getNormalLake(vec3 p) {
    float z = fract(p.z);
    float dydz = 0.1*M_2PI * cos(z*M_2PI);
    return normalize(vec3(0.0, dydz, 1.0));
}

vec2 getIntersectionD2(vec3 origin, vec3 dir) {
    float de = 0.001;
    int maxIter = 1256;
    int iter = 0;
    float k = 0.0;
    vec3 p = origin;
    float dist = distanceEstimate(p);
    while (abs(dist)>de && iter<maxIter) {
        k += abs(dist);
        p = origin + k*dir;
        dist = distanceEstimate(p);
        ++iter;
    }
//    return vec2(10.0, 0.0);
    return dist<de ? vec2(k, iter) : vec2(-1.0, iter);
}
vec2 getIntersectionD(vec3 ro, vec3 rd )
{
	float maxd = 70.0;

	float precis = 0.001;
    float h = 1.0;
    float t = 1.0;
    int iter = 0;
    for( int i=0; i<1256; i++ )
    {
        if( (h<precis) || (t>maxd) ) break;
	    h = distanceEstimate( ro+rd*t );
        t += h;
        ++iter;
    }

    if( t>maxd ) t=-1.0;
	return vec2(t, iter);
}

vec4 rrS(vec2 pos, vec2 outPos) {
    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;

    float eta = u_Intensity*0.01;

    vec3 origin = cameraPos;
    int maxIter = 12;
    int iter = maxIter;
    int minI = -1;
    float minK = OOB;
    float incidence = 2.0;
    vec4 reflectedColor = vec4(0.0, 0.0, 0.0, 1.0);
    float fniter = 0.0;

    do {
        minK = OOB;
        minI = -1;

        //float k = getIntersection(origin, dir);
        vec2 inters = getIntersectionD(origin, dir);
        float k = inters.x;
        fniter = inters.y;
        if (k>0.0 && k<minK) {
            minK = k;
            minI = 0;
        }

        if (minI >= 0) {
            vec3 intersection = origin + minK*dir;
            vec3 normal = getNormal(intersection);//distanceEstimate(origin)<=0.0 ? getNormal(intersection) : -getNormal(intersection);
            if (iter==maxIter) {
                incidence = abs(dot(normal, dir));
                vec3 reflectedDir = reflect(dir, normal);
                reflectedColor = background(reflectedDir);
            }
            dir = refract(dir, normal, eta);
            origin = intersection + dir*0.0001;
        }

        --iter;
    } while (minI>=0 && iter>0);

    vec4 col = background(dir);
    vec4 iterCol;
    if (iter==maxIter) iterCol = vec4(1.0, 1.0, 1.0, 1.0);
    else if (iter==maxIter-1) iterCol = vec4(1.0, 0.0, 0.0, 1.0);
    else if (iter==maxIter-2) iterCol = vec4(0.0, 1.0, 0.0, 1.0);
    else if (iter==maxIter-3) iterCol = vec4(0.0, 0.0, 1.0, 1.0);
    else iterCol = vec4(0.0, 0.0, 0.0, 1.0);

    vec4 mixedCol = mix(reflectedColor, col, clamp(0.0, 1.0, incidence + u_Balance*0.01));
    return mix(mixedCol, vec4(fniter/5.0, fniter==0.0 ? 1.0 : 0.0, fniter>=100.0 ? 1.0 :0.0, 1.0), 0.0);
//    return col;
//    return mix(col, iterCol, 0.25);//vec4(col.r, col.g, col.b*clamp(0.0, 1.0, float(iter+2)/4.0), col.a);
}

#include mainWithOutPos(rrS)
