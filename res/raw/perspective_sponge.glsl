precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include tex(1)
#include tex(2)

uniform int u_Count;
uniform float u_Intensity;
uniform float u_ColorScheme;
uniform float u_BackgroundStyle;
uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;

uniform float u_Gamma;
uniform float u_Shadows;
uniform float u_Specular;
uniform float u_SurfaceSmoothness;
uniform float u_NormalSmoothing;
uniform float u_LSDistance;
uniform float u_Variability;
uniform float u_Seed;
uniform mat3 u_LightSourceTransform;
uniform vec4 u_AmbientColor;
uniform vec4 u_SourceColor;
uniform int u_AddSub[11];
uniform int u_Shapes[11];

#define MAX_ITER 300
#define ERR .0005
#define OOB 1e9
#define N 25.0
#define S smoothstep

float hash3(vec3 u) {
    float k = (dot(u.xy, -u.yz)*644.2834-dot(u.zx, u.xy)*3184.43);
    float l = fract((u.x*u.z*20.01-33.110*u.y*u.x*k+23.32*u.z*u.y+u.x*2.11-u.y*33.454+u.z+k));
    return fract(45.4518*dot(vec3(k, u.xy), vec3(u.zy, l)));
}

float max3(vec3 u) {
    return max(max(u.x, u.y), u.z);
}

float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

mat2 rotate(float a) {
    float ca = cos(a);
    float sa = sin(a);
    return mat2(ca, -sa, sa, ca);
}

float getDist(vec3 q) {
    vec3 p = q;
    float dr = (0.1+0.1*sin(u_Seed*2.0*0.123));
    float r = 0.333333 + 0.25*sin(u_Seed*2.0*0.5);
	float d = u_Shapes[0]==0 ? sdBox(p, vec3(1.0, 1.0, 1.0)) : length(p)-1.0;
 	if (d>0.1) return d;
    float mul = 1.0;
    vec3 reflectNormal = normalize(vec3(-1.0, 1.0, 0.0));
    mat2 rot = rotate(max(0.0, (u_Variability-50.0))*0.04*u_Seed*2.0*0.1);

    vec3 offset = vec3(1.0, 0.0, 0.0);

    for(int i=0; i<u_Count; ++i) {
        vec3 qq = p;

        vec3 size = vec3(1.0, r, r);
        size[i] += clamp(q[i]*u_Variability*0.01*dr*5.0, 0.0, 1.0);
       	offset[i] += clamp(q[int(fmod(float(i+1), 3.0))]*u_Variability*0.01*dr*(r*15.0), 0.0, 1.0);

	    p = abs(p);

        if (p.y>p.x) p = p - 2.0*dot(reflectNormal, (p-reflectNormal*0.0))*reflectNormal;
        if (p.z>p.x) p = p - 2.0*dot(reflectNormal.xzy, p)*reflectNormal.xzy;

        //float d2 = -mul*sdBox(p-offset, 1.0*size);
        //float d2 = mul*sdBox(p-vec3(r*2.0, 0.0, 0.0), 1.5*vec3(1.0, r, r));
        if (u_Shapes[i+1]==0) d = max(d, u_AddSub[i]==0 ? -mul*sdBox(p-offset, 1.0*size) : mul*sdBox(p-vec3(r*2.0, 0.0, 0.0), 1.5*vec3(1.0, r, r)));
        else d = max(d, u_AddSub[i]==0 ? -mul*(length(p-offset)-1.0*r) : mul*(length(p-offset)-1.5*r));
        //if (d2<0.0) return d;

        //if (q[i]<0.0) {
        if (i<int(u_Variability/10.0-5.0)) {
            //p.xy *= rot;
        	p.yz *= rot;
        	//p += u_Variability*0.01 * vec3(rot[0], rot[1].x)*mul;
        }
        p = (fract((p+r)/(2.0*r))*2.0*r - r)/r;
        mul *= r;
        //r+=dr*q.x;
        //r+=dr*q[i];
        r = max(r+dr*u_Variability*0.01*q[i], 0.0); // avoid grain
    }

	return d;
}


vec3 rayMarch(vec3 origin, vec3 dir) {
	float d = 0.0;
    int i = 0;
    vec3 current = origin;
    while (i<MAX_ITER) {
        float dist = getDist(current);
        if (dist<ERR) break;
        current += dist*dir*0.8;
    	++i;
    }
    if (i>=MAX_ITER) return vec3(OOB, OOB, OOB);
    else return current;
}

float shadowMarch(vec3 origin, vec3 dir, float k) {
	float d = 0.0;
    int i = 0;
    vec3 current = origin;
    float light = 1.0;
    float t = 0.0;
    while (i<MAX_ITER) {
        float dist = getDist(current);
        if (dist<ERR) return 0.0;
        t += dist*1.0;
        current = origin+dir*t;
        light = min(light, k*dist/t);
    	++i;
    }
    return light;
}


vec3 getNormal(vec3 p) {
    float d = 0.0001;
    float d2 = d*2.0;
    return normalize(vec3(
        (getDist(vec3(p.x-d, p.y, p.z))-getDist(vec3(p.x+d, p.y, p.z)))/d2,
        (getDist(vec3(p.x, p.y-d, p.z))-getDist(vec3(p.x, p.y+d, p.z)))/d2,
        (getDist(vec3(p.x, p.y, p.z-d))-getDist(vec3(p.x, p.y, p.z+d)))/d2
        ));
}

vec3 getRayDir(vec2 uv, vec3 p, vec3 l, float z, float zoom) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + (uv.x*r + uv.y*u)/zoom,
        //i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

vec3 getColor(vec3 intersection, vec3 normal, float illum) {
    float COLOR_SCHEMES = 3.0;
    float colorScheme = u_ColorScheme*0.01*(COLOR_SCHEMES-1.0);
    if (colorScheme<=1.0) {
        vec3 col1 = abs(intersection.zxy);
        vec3 col2 = texture2D(u_Tex0, proj0(vec2(0.0, max3(abs(intersection)*2.0-1.0)))).rgb;
        return mix(0.1, 1.0, illum) * mix(col1, col2, colorScheme);
    }
    else {
        vec3 tu = abs(normal.x)>abs(normal.y) ? normalize(vec3(normal.z, 0.0, -normal.x)) : normalize(vec3(0.0, -normal.z, normal.y));
        vec3 tv = cross(normal, tu);
        vec3 col1 = texture2D(u_Tex0, proj0(vec2(0.0, max3(abs(intersection)*2.0-1.0)))).rgb;
        vec3 col2 = texture2D(u_Tex0, proj0(vec2(dot(tu, intersection)+normal.x, dot(tv, intersection)+normal.y))).rgb;
        return mix(0.1, 1.0, illum) * mix(col1, col2, colorScheme-1.0);
    }
}

vec3 getBackground(vec3 dir, vec3 lightDir) {
    float BKG_STYLES = 3.0;
    float bkgStyle = u_BackgroundStyle*0.01*(BKG_STYLES-1.0);
    if (bkgStyle<=1.0) {
        vec3 colSpectrum = abs(dir) + pow((dot(lightDir, dir)+1.0)/1.95, 50.0);

        float lightProx = dot(lightDir, dir);
        vec3 colDay = mix(vec3(0.0, 0.14, 0.85), vec3(0.2, 0.4, 1.0), (lightProx+1.0)/2.0) + 0.2*pow((lightProx+1.0)/1.95, 50.0);

        return mix(colSpectrum, colDay, bkgStyle);
    }
    else {
        float lightProx = dot(lightDir, dir);
        vec3 colDay = mix(vec3(0.0, 0.14, 0.85), vec3(0.2, 0.4, 1.0), (lightProx+1.0)/2.0) + 0.2*pow((lightProx+1.0)/1.95, 50.0);

        float R = 40.0;
        vec3 center = floor(dir*R+0.5)/R;
        float mag = pow(hash3(center), 10.0)*40.0;
        float stars1 = smoothstep(0.3, 1.0, mag*0.00000001/pow(length(center-dir), 2.5));
        R = 400.0;
        center = floor(dir*R+0.5)/R;
        mag = pow(hash3(center), 100.0)*4.0;
        float stars2 = smoothstep(0.3, 1.0, mag*0.00000001/pow(length(center-dir), 2.5));
        float mainStar = pow(max(0.0, lightProx)*1.001, 1000.0);
        vec3 colNight = vec3(0.0, 0.0, 0.0) + stars1 + stars2 + mainStar;

        return mix(colDay, colNight, bkgStyle-1.0);
    }
}

vec4 sponge(vec2 pos, vec2 outPos) {
    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;
    vec3 origin = cameraPos;

    vec3 lightDir = u_LightSourceTransform*vec3(0.0, 0.0, 1.0); //normalize(vec3(-1.0, 1.85, 2.5));
    vec3 col;// = abs(dir) + pow((dot(lightDir, dir)+1.0)/1.95, 50.0);

    float ambient = 0.2;
    float source = 1.5;
    float fogStart = 15.0;
    float fogEnd = 20.0;

    vec3 intersection = rayMarch(origin, dir);
    if (intersection.x!=OOB) {
        //col = 0.5*(0.5-2.0*getNormal(intersection));
        vec3 normal = -getNormal(intersection);
        //vec3 u = normalize(vec3(0.0, -normal.z, normal.y));

        /*vec3 tu = abs(normal.x)>abs(normal.y) ? normalize(vec3(normal.z, 0.0, -normal.x)) : normalize(vec3(0.0, -normal.z, normal.y));
        vec3 tv = cross(normal, tu);*/

        float illum = clamp(dot(normal, lightDir), 0.0, 1.0);

        //col = intersection.zxy * illum;//getNormal(intersection).zxy;
        //col = mix(0.1, 1.0, illum) * texture2D(u_Tex0, proj0(vec2(dot(tu, intersection)+normal.x, dot(tv, intersection)+normal.y))).rgb;
        //col = /*vec3(1.0)*/ getNormal(intersection).xyz* dot(getNormal(intersection).xyz, lightDir);
        col = getColor(intersection, normal, illum);

        /*vec3 lInt = rayMarch(intersection+lightDir*0.002, lightDir);
        if (lInt.x!=OOB) col *= 0.3;*/

        float light = 1.0;

        if (u_Shadows!=0.0 || u_Specular!=0.0) {
           // light = shadowMarch(intersection+lightDir*0.005, lightDir, 10.0);
            light = rayMarch(intersection+lightDir*0.01, lightDir).x==OOB ? 1.0 : 0.0;
            col *= mix(1.0-u_Shadows*0.01, 1.0, light);
        }

        float specular = light*clamp(dot(normalize(reflect(dir, normal)), lightDir), 0.0, 1.0);
        col += u_Specular*0.02*pow(specular, 20.0-u_Specular*0.1);
    }
    else {
        col = getBackground(dir, lightDir);
    }

    //col = clamp(col, 0.0, 1.0);
    col = pow(col, vec3(0.5));	// gamma correction

    return vec4(col,1.0);
}

#include mainWithOutPos(sponge)
