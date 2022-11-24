precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include tex(2)

uniform int u_Count;
uniform float u_Intensity;
uniform float u_ColorScheme;
uniform float u_BackgroundStyle;
uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;
uniform mat3 u_InverseViewTransform;

#include bkg3d2

uniform float u_Thickness;
uniform float u_Gamma;
uniform float u_Shadows;
uniform float u_Glow;
uniform float u_Fog;
uniform float u_Specular;
uniform float u_SurfaceSmoothness;
uniform float u_NormalSmoothing;
uniform float u_LSDistance;
uniform float u_Variability;
uniform float u_Seed;
uniform float u_Balance;
uniform float u_Detail;
uniform float u_Phase;
uniform mat3 u_LightSourceTransform;
uniform vec4 u_AmbientColor;
uniform vec4 u_SourceColor;
uniform int u_AddSub[11];
uniform vec2 u_Params[11];
uniform mat4 u_FractTransform;

#define MAX_ITER 80
#define ERR .0005
//#define ERR .0005
#define OOB 1e9
//#define N 25.0
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

float getDist(vec3 q) {
    vec3 p = q;

	float d;
	d = sdBox(p, vec3(1.0, 1.0, 1.0));

 	if (d>0.1) return d;
    float mul = 1.0;
    vec3 reflectNormal = normalize(vec3(-1.0, 1.0, 0.0));
    float variability = u_Variability*0.01;

    vec3 offset = vec3(u_Thickness*0.02, 0.0, 0.0);

    int j = variability<0.0 ? 2 : 1;
    float lowR = 0.0;
    float highR = 0.6;

    for(int i=0; i<u_Count-1; ++i) {
        if (j==3) j = 0;
        float var = q[i];
        float dr = u_Params[i].y;
        float r = clamp(abs(u_Params[i].x + (i>0 ? dr*variability*var : 0.0)), lowR, highR);

        vec3 qq = p;

        vec3 size = vec3(1.05, r, r);
        if (i>0) size += clamp(q[i]*variability*vec3(u_Params[1].y, u_Params[2].y, u_Params[3].y)*5.0, -1.0, 1.0);
       	offset[j] += clamp(q[i]*variability*dr*(r*15.0), 0.0, 1.0);

	    p = abs(p);

        if (p.y>p.x) p = p - 2.0*dot(reflectNormal, (p-reflectNormal*0.0))*reflectNormal;
        if (p.z>p.x) p = p - 2.0*dot(reflectNormal.xzy, p)*reflectNormal.xzy;

        float d2 = u_AddSub[i]==0 ? -mul*sdBox(p-offset, 1.0*size) : mul*sdBox(p-offset, 1.5*vec3(1.0, r, r));
        d = max(d, d2);

        p = (fract((p+r)/(2.0*r))*2.0*r - r)/r;
        mul *= r;
    }

	return d;
}

vec3 rayMarch(vec3 origin, vec3 dir, int maxIter) {
	float d = 0.0;
    int i = 0;
    vec3 current = origin;
    while (i<maxIter) {
        float dist = getDist(current);
        if (dist<ERR) break;
        current += dist*dir*1.0;
    	++i;
    }
    if (i>=maxIter) return vec3(OOB);
    else return current;
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

vec3 getColor(vec3 intersection, vec3 normal, float illum) {
    float COLOR_SCHEMES = 3.0;
    float colorScheme = u_ColorScheme*0.01*(COLOR_SCHEMES-1.0);
    if (colorScheme<=1.0) {
        vec3 col1 = abs(intersection.zxy);
        vec3 col2 = texture2D(u_Tex0, proj0(vec2(0.0, max3(abs(intersection)*2.0-1.0)))).rgb;
        return mix(0.1, 1.0, illum) * mix(col1, col2, colorScheme);
    }
    else {
        vec3 tu = abs(normal.x)>=abs(normal.y) ? normalize(vec3(normal.z, 0.0, -normal.x)) : normalize(vec3(0.0, -normal.z, normal.y));
        vec3 tv = cross(normal, tu);
        vec3 col1 = texture2D(u_Tex0, proj0(vec2(0.0, max3(abs(intersection)*2.0-1.0)))).rgb;
        vec3 col2 = texture2D(u_Tex0, proj0(vec2(dot(tu, intersection)+normal.x*2.0, dot(tv, intersection)+normal.y*2.0))).rgb;
        return mix(0.1, 1.0, illum) * mix(col1, col2, colorScheme-1.0);
    }
}

vec3 getBackground(vec3 dir, vec3 lightDir) {
    float BKG_STYLES = 5.0;
    float bkgStyle = u_BackgroundStyle*0.01*(BKG_STYLES-1.0);
    if (bkgStyle<=1.0) {
        float lightProx = dot(lightDir, dir);
        return background(dir).rgb + bkgStyle*0.2*pow((lightProx+1.0)/1.95, 100.0)*u_SourceColor.rgb;
    }
    if (bkgStyle<=2.0) {
        float lightProx = dot(lightDir, dir);
        vec3 colImg = background(dir).rgb + 0.2*pow((lightProx+1.0)/1.95, 100.0)*u_SourceColor.rgb;
        vec3 colSpectrum = abs(dir) + pow((dot(lightDir, dir)+1.0)/1.95, 50.0);
        return mix(colImg, colSpectrum, bkgStyle-1.0);
    }
    if (bkgStyle<=3.0) {
        vec3 colSpectrum = abs(dir) + pow((dot(lightDir, dir)+1.0)/1.95, 50.0);

        float lightProx = dot(lightDir, dir);
        vec3 colDay = mix(vec3(0.03, 0.12, 0.82), vec3(0.2, 0.4, 1.0), (lightProx+1.0)/2.0) + 0.2*pow((lightProx+1.0)/1.95, 100.0)*u_SourceColor.rgb;

        return mix(colSpectrum, colDay, bkgStyle-2.0);
    }
    else {
        float lightProx = dot(lightDir, dir);
        vec3 colDay = mix(vec3(0.0, 0.14, 0.85), vec3(0.2, 0.4, 1.0), (lightProx+1.0)/2.0) + 0.2*pow((lightProx+1.0)/1.95, 100.0)*u_SourceColor.rgb;

        float R = 40.0;
        vec3 center = floor(dir*R+0.5)/R;
        float mag = pow(hash3(center), 10.0)*40.0;
        float stars1 = smoothstep(0.3, 1.0, mag*0.00000001/pow(length(center-dir), 2.5));
        R = 400.0;
        center = floor(dir*R+0.5)/R;
        mag = pow(hash3(center), 100.0)*4.0;
        float stars2 = smoothstep(0.3, 1.0, mag*0.00000001/pow(length(center-dir), 2.5));
        float mainStar = pow(max(0.0, lightProx)*1.001, 1000.0);
        vec3 colNight = vec3(0.0) + stars1 + stars2 + mainStar*u_SourceColor.rgb;

        return mix(colDay, colNight, bkgStyle-3.0);
    }
}

vec4 sponge(vec2 pos, vec2 outPos) {
    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;
    vec3 origin = cameraPos;

    vec3 lightDir = u_LightSourceTransform*vec3(0.0, 0.0, 1.0);
    vec3 col;

    vec3 intersection = rayMarch(origin, dir, MAX_ITER);

    if (intersection.x!=OOB) {
        vec3 normal = -getNormal(intersection);
        float illum = clamp(dot(normal, lightDir), 0.0, 1.0);
        col = getColor(intersection, normal, illum);
        float light = 1.0;

        if ((u_SourceColor.a!=0.0 && (u_SourceColor.r!=0.0 || u_SourceColor.g!=0.0 || u_SourceColor.b!=0.0))
                || u_Specular!=0.0) {
            light = rayMarch(intersection+lightDir*0.01, lightDir, 30).x==OOB ? 1.0 : 0.0;
            col = u_AmbientColor.rgb*col + light*u_SourceColor.rgb*col;
        }
        else {
            col = u_AmbientColor.rgb*col;
        }

        float specular = light*clamp(max(u_Specular*0.01-0.5, 0.0) + dot(normalize(reflect(dir, normal)), lightDir), 0.0, 1.0);
        col += u_Specular*u_SourceColor.rgb*0.04*pow(specular, 20.0-u_Specular*0.1);
    }
    else {
        col = getBackground(dir, lightDir);
    }

    if (u_Fog!=0.0) {
        float near = u_Fog<10.0 ? 1e10/pow(u_Fog, 10.0) : 100.0/(u_Fog*u_Fog); ///(u_Fog+1e-10);
        float far = near*10.0;
        col = mix(col, u_AmbientColor.rgb, smoothstep(near, far, length(origin-intersection.xyz)));
    }

    col = pow(col, vec3(1.0-u_Gamma*0.01));

    return vec4(col,1.0);
}

#include mainWithOutPos(sponge)
