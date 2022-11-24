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
uniform vec4 u_GlowColor;
uniform int u_AddSub[11];
uniform int u_Shapes[11];
uniform vec2 u_Params[11];
uniform vec2 u_GlowParams[11];
uniform mat4 u_FractTransform;

#define MAX_ITER 200
#define ERR .00005
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

float sdTorus( vec3 p, vec2 t ) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdPyramid( vec3 p, float h)
{
  float m2 = h*h + 0.25;

  p.xz = abs(p.xz);
  p.xz = (p.z>p.x) ? p.zx : p.xz;
  p.xz -= 0.5;

  vec3 q = vec3( p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);

  float s = max(-q.x,0.0);
  float t = clamp( (q.y-0.5*p.z)/(m2+0.25), 0.0, 1.0 );

  float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
  float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);

  float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);

  return sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y));
}

mat2 rotate(float a) {
    float ca = cos(a);
    float sa = sin(a);
    return mat2(ca, -sa, sa, ca);
}

float getVar(float x) {
    if (u_Variability>=0.0) return x;
    else return fract(x*3.0);
    /*if (u_Balance==0.0) return x;
    float M = floor(101.0-abs(u_Balance));
    if (u_Balance>0.0) return floor(x*M)/M;
    else {
        float y = floor(x*M);
        y = y*(1.0+y*u_Balance);
        return fract(y/M);
    }*/
}

vec2 getDistAndGlow(vec3 q, vec2 params) {
    vec3 p = q;
    float dr0 = params.y; //(0.1+0.1*sin(u_Seed*2.0*0.123));
    float r0 = params.x; // 0.333333 + 0.25*sin(u_Seed*2.0*0.5);

	float d;
	if (u_Shapes[0]==0) d = sdBox(p, vec3(1.0, 1.0, 1.0));
	else if (u_Shapes[0]==1) d = length(p)-1.0;
	else if (u_Shapes[0]==2) d = 2.0*sdPyramid(-p*0.5+vec3(0.0, 0.5, 0.0), 1.0);
	else  d = sdTorus(p.xzy, vec2(1.0, 0.33));
	 //= u_Shapes[0]==0 ? sdBox(p, vec3(1.0, 1.0, 1.0)) : 2.0*sdPyramid(-p*0.5+vec3(0.0, 0.5, 0.0), 1.0); //sdTorus(p, vec2(1.0, 0.33)); //length(p)-1.0;

 	if (d>(u_GlowColor.a>0.0 ? 1.0 : 0.1)) return vec2(d, 0.0);
    float mul = 1.0;
    vec3 reflectNormal = normalize(vec3(-1.0, 1.0, 0.0));
    float variability = u_Variability*0.01;
    //mat2 rot = rotate(max(0.0, (u_Variability-50.0))*0.004*u_Seed*2.0*0.1);
    //mat2 rot = rotate(u_Phase);

    vec3 offset = vec3(u_Thickness*0.02, 0.0, 0.0);
//    vec3 offset = vec3(1.0, 0.0, 0.0);
    float glow = 0.0;
    int rotN = int(pow(2.0, abs(u_Phase)/M_PI*2.0));

    int j = variability<0.0 ? 2 : 1;
    float lowR = variability<0.0 ? 0.1 : 0.0;
    float highR = variability<0.0 ? 0.5 : 0.6;

    for(int i=0; i<u_Count-1; ++i) {
        if (j==3) j = 0;
        float dr = mix(dr0, u_Params[i].y, u_Balance*0.01);
        float var = getVar(q[i]);
        //float r = mix(r0, max(u_Thickness*0.01, abs(u_Params[i].x + (i>0 ? dr*variability*var : 0.0))), u_Balance*0.01);
        //float r = max(u_Thickness*0.01, mix(r0, abs(u_Params[i].x + (i>0 ? dr*variability*var : 0.0)), u_Balance*0.01));
        //float r = max(0.0, mix(r0, abs(u_Params[i].x + (i>0 ? dr*variability*var : 0.0)), u_Balance*0.01));
        float r = clamp(mix(r0, abs(u_Params[i].x + (i>0 ? dr*variability*var : 0.0)), u_Balance*0.01), lowR, highR);

        vec3 qq = p;

        vec3 size = vec3(1.05, r, r);
        //size[i] += clamp(q[i]*variability*dr*5.0, -1.0, 1.0);
        //if (i>0) size += clamp(q[i]*variability*vec3(u_Params[0].y, u_Params[1].y, u_Params[2].y)*5.0, -1.0, 1.0);
        if (i>0) size += clamp(q[i]*variability*vec3(u_Params[1].y, u_Params[2].y, u_Params[3].y)*5.0, -1.0, 1.0);
//        if (i>0) size += clamp(var*variability*vec3(u_Params[0].y, u_Params[1].y, u_Params[2].y)*5.0, -1.0, 1.0);
//       	offset[i] += clamp(q[int(fmod(float(i+1), 3.0))]*variability*dr*(r*15.0), 0.0, 1.0);
//       	offset[int(fmod(float(i+1), 3.0))] += clamp(q[i]*variability*dr*(r*15.0), 0.0, 1.0);
       	offset[j] += clamp(q[i]*variability*dr*(r*15.0), 0.0, 1.0);

	    p = abs(p);

        if (p.y>p.x) p = p - 2.0*dot(reflectNormal, (p-reflectNormal*0.0))*reflectNormal;
        if (p.z>p.x) p = p - 2.0*dot(reflectNormal.xzy, p)*reflectNormal.xzy;
//    if (p.y>p.x && p.y>p.z) {
//        p.xy = p.yx;
//        if (p.z>p.y) p.yz = p.zy;
//    }
//    else if (p.z>p.y && p.z>p.x) {
//        p.xz = p.zx;
//        if (p.z>p.y) p.yz = p.zy;
//    }
//    else {
//        if (p.z>p.y) p.yz = p.zy;
//    }

        //float d2 = -mul*sdBox(p-offset, 1.0*size);
        //float d2 = mul*sdBox(p-vec3(r*2.0, 0.0, 0.0), 1.5*vec3(1.0, r, r));
        float d2;
        float signD = u_AddSub[i]==0 ? -1.0 : 1.0;
        if (u_Shapes[i+1]==0) d2 = u_AddSub[i]==0 ? -mul*sdBox(p-offset, 1.0*size) : mul*sdBox(p-offset, 1.5*vec3(1.0, r, r));
        else d2 = u_AddSub[i]==0 ? -mul*(length(p-offset)-1.0*r) : mul*(length(p-offset)-1.5*r);
        //if (d2<0.0) return d;

//        if (i>=0) glow = max(glow, clamp(u_Glow*0.001*pow(0.25, 1.0+float(i))*mul/abs(d+signD*d2), 0.0, 10.0));
        //glow = max(glow, mul*(u_GlowParams[i].x/abs(d+signD*d2) + u_GlowParams[i].y/abs(d)));
        //glow = max(glow, mul*dot(u_GlowParams[i], 1.0/abs(vec2(d+signD*d2, d))));
        glow = max(glow, mul*u_GlowParams[i].x/abs(d+signD*d2));

        d = max(d, d2);

        //if (var<0.0) {
        if (i<rotN && u_Phase!=0.0) {
            //p.xy *= rot;
        	//p.yz *= rot;
        	p = (u_FractTransform*vec4(p, 1.0)).xyz;
        	//p += variability * vec3(rot[0], rot[1].x)*mul;
        }
        p = (fract((p+r)/(2.0*r))*2.0*r - r)/r;
        mul *= r;
//        r0 = max(r0+dr0*u_Variability*0.01*q[i], 0.0);
        //r0 = max(r0+dr0*u_Variability*0.01*mix(1.0, sin(q[i]*6.0), u_Detail*0.02), 0.0);
        //r0 = max(r0+dr0*u_Variability*0.01*mix(1.0, sin(q[i]*(12.0-u_Detail*0.1)), u_Detail*0.02), 0.0);
        r0 = max(r0+dr0*u_Variability*0.01*mix(1.0, sin(floor(q[i]*8.0+0.5)/8.0*(12.0-u_Detail*0.1)), u_Detail*0.02), 0.0);
        //r+=dr*q.x;
        //r+=dr*q[i];
        //r = max(r+dr*variability*q[i], 0.0); // avoid grain
    }

	return vec2(d, glow);
}
/*
vec2 getDistAndGlow(vec3 q, vec2 params) {
    vec3 p = q;
    float dr0 = params.y; //(0.1+0.1*sin(u_Seed*2.0*0.123));
    float r0 = params.x; // 0.333333 + 0.25*sin(u_Seed*2.0*0.5);

	float d;
	if (u_Shapes[0]==0) d = sdBox(p, vec3(1.0, 1.0, 1.0));
	else if (u_Shapes[0]==1) d = length(p)-1.0;
	else if (u_Shapes[0]==2) d = 2.0*sdPyramid(-p*0.5+vec3(0.0, 0.5, 0.0), 1.0);
	else  d = sdTorus(p.xzy, vec2(1.0, 0.33));

 	if (d>(u_GlowColor.a>0.0 ? 1.0 : 0.1)) return vec2(d, 0.0);
    float mul = 1.0;
    vec3 reflectNormal = normalize(vec3(-1.0, 1.0, 0.0));
    float variability = u_Variability*0.01;

    vec3 offset = vec3(u_Thickness*0.02, 0.0, 0.0);
//    vec3 offset = vec3(1.0, 0.0, 0.0);
    float glow = 0.0;
    int rotN = int(pow(2.0, abs(u_Phase)/M_PI*2.0));

    for(int i=0; i<u_Count; ++i) {
        float dr = mix(dr0, u_Params[i].y, u_Balance*0.01);
        float var = getVar(q[i]);
        float r = clamp(mix(r0, abs(u_Params[i].x + (i>0 ? dr*variability*var : 0.0)), u_Balance*0.01), 0.0, 0.6);

        vec3 qq = p;

        vec3 size = vec3(2.05, r, r);
        if (i>0) size += clamp(q[i]*variability*vec3(u_Params[0].y, u_Params[1].y, u_Params[2].y)*5.0, -1.0, 1.0);
       	offset[i] += clamp(q[int(fmod(float(i+1), 3.0))]*variability*dr*(r*15.0), 0.0, 1.0);

	    //p = abs(p);

        if (p.y>p.x) p = p - 2.0*dot(reflectNormal, (p-reflectNormal*0.0))*reflectNormal;
        if (p.z>p.x) p = p - 2.0*dot(reflectNormal.xzy, p)*reflectNormal.xzy;

        float d2;
        float signD = u_AddSub[i]==0 ? -1.0 : 1.0;
        if (u_Shapes[i+1]==0) d2 = u_AddSub[i]==0 ? -mul*sdBox(p-offset, 1.0*size) : mul*sdBox(p-offset, 1.5*vec3(1.0, r, r));
        else d2 = u_AddSub[i]==0 ? -mul*(length(p-offset)-1.0*r) : mul*(length(p-offset)-1.5*r);

        glow = max(glow, mul*dot(u_GlowParams[i], 1.0/abs(vec2(d+signD*d2, d))));

        d = max(d, d2);

        if (i<rotN && u_Phase!=0.0) {
        	p = (u_FractTransform*vec4(p, 1.0)).xyz;
        }
        p = (fract((p+r)/(2.0*r))*2.0*r - r)/r;
        mul *= r;
        r0 = max(r0+dr0*u_Variability*0.01*mix(1.0, sin(floor(q[i]*8.0+0.5)/8.0*(12.0-u_Detail*0.1)), u_Detail*0.02), 0.0);
    }

	return vec2(d, glow);
}*/

float getDist(vec3 q, vec2 params) {
    return getDistAndGlow(q, params).x;
}


mat3 rayMarch(vec3 origin, vec3 dir, vec2 params) {
	float d = 0.0;
    int i = 0;
    vec3 current = origin;
    float glow = 0.0;
    while (i<MAX_ITER) {
        vec2 distGlow = getDistAndGlow(current, params);
        float dist = distGlow.x;
        glow = max(glow, distGlow.y);
        if (dist<ERR) break;
        current += dist*dir*0.8;
    	++i;
    }
    if (i>=MAX_ITER) return mat3(vec3(OOB), vec3(glow, i, 0.0), vec3(0.0));
    else return mat3(current, vec3(glow, i, 0.0), vec3(0.0));
}

/*float shadowMarch(vec3 origin, vec3 dir, float k) {
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
}*/

vec3 getNormal(vec3 p, vec2 params) {
    float d = 0.0001;
    float d2 = d*2.0;
    return normalize(vec3(
        (getDist(vec3(p.x-d, p.y, p.z), params)-getDist(vec3(p.x+d, p.y, p.z), params))/d2,
        (getDist(vec3(p.x, p.y-d, p.z), params)-getDist(vec3(p.x, p.y+d, p.z), params))/d2,
        (getDist(vec3(p.x, p.y, p.z-d), params)-getDist(vec3(p.x, p.y, p.z+d), params))/d2
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

    vec3 lightDir = u_LightSourceTransform*vec3(0.0, 0.0, 1.0); //normalize(vec3(-1.0, 1.85, 2.5));
    vec3 col;// = abs(dir) + pow((dot(lightDir, dir)+1.0)/1.95, 50.0);

    float ambient = 0.2;
    float source = 1.5;

//    vec2 params =  vec2(0.333333 + 0.25*sin(u_Seed*2.0*0.5), 0.1+0.1*sin(u_Seed*2.0*0.123));
    vec2 params =  vec2(0.40 + 0.15*sin(-0.4605539919293922+u_Seed*2.0*0.5), 0.1+0.1*sin(u_Seed*2.0*0.123));

    mat3 intersectionGlow = rayMarch(origin, dir, params);
    vec3 intersection = intersectionGlow[0];
    float glow = intersectionGlow[1].x;
    float iterations = intersectionGlow[1].y;

    if (intersection.x!=OOB) {
        //col = 0.5*(0.5-2.0*getNormal(intersection));
        vec3 normal = -getNormal(intersection, params);
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

        if ((u_SourceColor.a!=0.0 && (u_SourceColor.r!=0.0 || u_SourceColor.g!=0.0 || u_SourceColor.b!=0.0))
                || u_Specular!=0.0) {
           // light = shadowMarch(intersection+lightDir*0.005, lightDir, 10.0);
            light = rayMarch(intersection+lightDir*0.01, lightDir, params)[0].x==OOB ? 1.0 : 0.0;
            //col *= mix(1.0-u_Shadows*0.01, 1.0, light);
            col = u_AmbientColor.rgb*col + light*u_SourceColor.rgb*col;//mix(1.0-u_Shadows*0.01, 1.0, light);
        }
        else {
            col = u_AmbientColor.rgb*col;
        }

        float specular = light*clamp(max(u_Specular*0.01-0.5, 0.0) + dot(normalize(reflect(dir, normal)), lightDir), 0.0, 1.0);
        //col += u_Specular*0.02*pow(specular, 20.0-u_Specular*0.1);
        col += u_Specular*u_SourceColor.rgb*0.04*pow(specular, 20.0-u_Specular*0.1);
    }
    else {
        col = getBackground(dir, lightDir);
    }

    col += glow*u_GlowColor.a*u_GlowColor.rgb;

    //col = vec3(iterations*0.01);
    if (intersection.x!=OOB) {
        col = mix(col, max(vec3(0.0), 1.5-iterations*0.1*(1.0-u_GlowColor.rgb*0.5)), u_GlowParams[0].y*u_GlowColor.a);
        col = mix(col, u_GlowColor.rgb*vec3(iterations)*0.01, u_GlowParams[1].y*u_GlowColor.a);
//        col = mix(col, max(vec3(0.0), 2.5-iterations*0.1*(1.0-u_GlowColor.rgb)), u_GlowParams[1].y*u_GlowColor.a);
//        if (glowGrey>0.5) col = mix(col, u_GlowColor.rgb*vec3(iterations)*0.01, u_GlowParams[0].y);
//        else {
//    //        col = mix(col, max(vec3(0.0), 1.5-vec3(iterations)*0.04), u_GlowParams[0].y);
//            col = mix(col, max(vec3(0.0), 1.5-iterations*0.1*(0.5-u_GlowColor.rgb)), u_GlowParams[0].y);
//        }
//        col = mix(
//                col,
//                mix(u_GlowColor.rgb*vec3(iterations)*0.01, max(vec3(0.0), 2.5-iterations*0.1*(1.0-u_GlowColor.rgb)), u_GlowColor.a),
//                u_GlowParams[1].y );
    }

//    col = mix(col, col+u_GlowColor.rgb*iterations*0.01, u_GlowParams[1].y);
//    col = col + u_GlowColor.rgb*iterations*0.01*u_GlowParams[2].y;
//    col = mix(col, 2.0*col*abs(length(intersection)*0.25-iterations*0.01), u_GlowParams[1].y);
//    col = mix(col, col*vec3(iterations)*0.01, u_GlowParams[2].y);

    if (u_Fog!=0.0) {
        //float near = mix(1e9/u_Fog, 100.0/(u_Fog*u_Fog), smoothstep(1.0, 10.0, u_Fog)); ///(u_Fog+1e-10);
        float near = u_Fog<10.0 ? 1e10/pow(u_Fog, 10.0) : 100.0/(u_Fog*u_Fog); ///(u_Fog+1e-10);
        float far = near*10.0;
        col = mix(col, u_AmbientColor.rgb, smoothstep(near, far, length(origin-intersection.xyz)));
    }

    col = pow(col, vec3(1.0-u_Gamma*0.01));

    return vec4(col,1.0);
}

#include mainWithOutPos(sponge)
