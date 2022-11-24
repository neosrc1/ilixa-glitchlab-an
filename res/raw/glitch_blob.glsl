precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random
#include hsl
#include locuswithcolor

uniform int u_Count;
uniform float u_Intensity;
uniform float u_Balance;
uniform float u_Regularity;
uniform float u_Power;
uniform float u_Mode;
uniform float u_Mode2;
uniform float u_Seed;
uniform float u_Shadows;
uniform float u_TextureScale;
uniform float u_Distortion;
uniform float u_Pixelation;
uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform mat3 u_GlitchTransform;

vec2 fmod2(vec2 a, float b) {
	return vec2(a.x - b*floor(a.x/b), a.y - b*floor(a.y/b));
}
float distInf(vec2 u) {
    return max(abs(u.x), abs(u.y));
}

float refract(float x) {
    x = fmod(x, 2.0);
    if (x<=1.0) return fract(x);
    else return 2.0-x;
}

float getVal(vec3 c) {
    return (c.r+c.g+c.b)/3.0;
}

float getValue(vec2 p) {
    vec4 c = texture2D(u_Tex0, p);
    return (c.r+c.g+c.b)/3.0;
}

vec3 max3(vec3 a, vec3 b) {
    return vec3(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z));
}

float getCheckerboard(vec2 uv, float textureScale) {
 	float s = floor(uv.x*textureScale)+floor(uv.y*textureScale);
    if (fract(s/2.0)==0.0) return 1.0; else return 0.0;
}

vec4 getCheckerboard4(vec2 uv, float textureScale) {
 	float s = floor(uv.x*textureScale)+floor(uv.y*textureScale);
    if (fract(s/2.0)==0.0) return u_Color1; else return u_Color2;
}

float getPerspectiveShading(vec2 uv) {
 	float s = max(floor(pow(abs(uv.x-0.5), 0.5)*100.0), floor(pow(abs(uv.y-0.5), 0.5)*100.0));
    if (fract(s/2.0)==0.0) return 1.0; else return 0.0;
}

mat2 rotate(float a) {
    float ca = cos(a);
    float sa = sin(a);
    return mat2(ca, sa, -sa, ca);
}


vec4 keepChannel(vec4 c, int index) {
	if (index!=0) c.r = 0.0;
	if (index!=1) c.g = 0.0;
	if (index!=2) c.b = 0.0;
    c[index] *= 3.0;
    return c;
}

vec4 getColor(vec4 inCol, vec2 pos, vec2 uv) {
    float STEP = u_Power;
    float mode = u_Mode;
    float mode2 = u_Mode2;
    bool INVERT = fmod(mode, 2.0)>=1.0; mode /= 2.0;
    bool CIRCULAR = fmod(mode, 2.0)<1.0; mode /= 2.0;
    int DIR = int(fmod(mode, 16.0)); mode /= 16.0;
    float textureScale = 100.0*length(u_GlitchTransform[0].xy);
    float step = 0.001*STEP;
    float scale = length(u_ModelTransform[0].xy);
    float sampleScale = u_Pixelation<=0.0 ? 0.0 : 100.0/u_Pixelation;//pow(fmod(mode, 16.0), 3.0); mode /= 16.0;

    int maxIter = u_Count; // just to ensure compute times don't go overboard
    vec2 dir = (INVERT?-1.0:1.0) * normalize(uv-pos);
    vec2 origdir = dir;


    float k = 0.0;
    //float dist = max(abs(pos.x-uv.x), abs(pos.y-uv.y));//length(pos-uv);
    float dist = CIRCULAR ? length(pos-uv) : max(abs(pos.x-uv.x), abs(pos.y-uv.y));
    vec2 p = INVERT ? uv : pos;
    vec2 q = p;
    float d;
    vec3 origCol = inCol.rgb;
    vec3 totColDiff = vec3(0.0);
    float totValDiff = 0.0;
    vec3 maxC = vec3(0.0);
    vec3 minC = vec3(1.0);
    float sumV = 0.0;
    float maxV = 0.0;
    float maxVDist = 0.0;
    mat2 defaultRotation = rotate(0.0005*u_Intensity);
    vec2 halfP;
    for(d = 0.0; d<dist; d+=step) {
        q += dir*step;
        p = (sampleScale>0.0) ? floor(q*sampleScale)/sampleScale : q;
        if (d<dist*0.5) halfP = p;
        vec3 col = texture2D(u_Tex0, proj0(p)).rgb;
        totValDiff += length(col-origCol);
        totColDiff += col-origCol;
        float v = (col.r+col.g+col.b)/3.0;
        sumV += v;
        maxC = max(maxC, col);
        minC = min(minC, col);
        k += 0.001*v;
        if (v>maxV) { maxV = v; maxVDist = d; }

        if (DIR==1) dir = defaultRotation*dir;
        else if (DIR==2) dir = rotate(0.0005*u_Intensity*(col.r-col.b))*dir;
        else if (DIR==3) dir = fmod(sumV*0.1, 2.0)<1.0 ? normalize(vec2(origdir.x, 0.0)) : normalize(vec2(0.0, origdir.y));
        else if (DIR==4) dir = fmod(sumV*0.1, 2.0)<1.0 ? (vec2(origdir.x, 0.0)) : (vec2(0.0, origdir.y));
        else if (DIR==5) dir = fmod(maxV*50.0, 2.0)<1.0 ? normalize(vec2(origdir.x, 0.0)) : normalize(vec2(0.0, origdir.y));
        else if (DIR==6) dir = normalize(dir+0.001*u_Intensity*(col.xy-0.5));
        else if (DIR==7) dir = dir+0.001*u_Intensity*(col.xy-0.5);
        else if (DIR==8) { if (length(dir)<2.0) dir *= (col.r-0.5)*0.001*u_Intensity + 1.0; }
        else if (DIR==9) dir = mix(origdir, normalize(totColDiff.xy-totColDiff.z), length(p-pos)*10.0);
        else if (DIR==10) dir = pos*5.0;

        --maxIter;
        if (maxIter<0) break;
        //if (totValDiff>30.0) break;
    }
    vec2 t = u_GlitchTransform[2].xy;

//    vec2 v = mix(p, uv, min(length(uv-pos)/1.5, 1.0));
    vec2 v = mix(uv, mix(p, uv, min(length(uv-pos)/1.5, 1.0)), u_Distortion*0.02);

    vec2 iv = floor((t+v)*textureScale)/textureScale;
    vec2 fv = floor(fmod2((t+v)*textureScale, 2.0));
    bool even = fract(floor((t.x+v.x)*textureScale)/2.0)==0.0;
    vec2 pix = vec2(floor(p.x*textureScale)/textureScale, p.y);
    int rgbIndexX = int(floor(fmod(t.x+v.x*textureScale, 3.0)));

    //float insidness = 0.1/k;
    float insidness = k*STEP/scale;
    //float insidness = totValDiff/(30.0*scale);
    bool inside = insidness<1.0;


    int STYLE = int(fmod(mode2, 50.0));
    mode2 /= 50.0;
    if (inside) {
        vec4 iCol = vec4(0.0, 0.0, 0.0, 1.0);
        if (STYLE==0) iCol =  texture2D(u_Tex0, proj0(iv)); // distortion
        else if (STYLE==1) iCol =  texture2D(u_Tex0, proj0((u_GlitchTransform*vec3(v, 1.0)).xy)); // distortion
        else if (STYLE==2) iCol =  vec4(vec3(floor(fract((t.x + totColDiff)*textureScale*0.001*STEP)*2.0)), 1.0); // saturated concentric bands
        else if (STYLE==3) iCol = even ? texture2D(u_Tex0, proj0(v)): getCheckerboard4(v+t, textureScale); // partial checkerboard/distortion
        else if (STYLE==4) iCol =  keepChannel(texture2D(u_Tex0, proj0(v)), rgbIndexX); // RGB bands
        else if (STYLE==5) iCol =  texture2D(u_Tex0, proj0(v))*mix(0.25, 1.0, smoothstep(0.21, 0.18, k))*vec4(vec3(sumV/maxV)*0.004, 1.0); // dark veil

        else if (STYLE==6) iCol = vec4(maxC, 1.0); // lightest
        else if (STYLE==7) iCol = vec4(minC, 1.0); // darkest
        else if (STYLE==8) iCol = vec4(abs(getVal(maxC)-0.5) > abs(getVal(minC)-0.5) ? maxC : minC, 1.0); // strongest
        else if (STYLE==9) iCol = vec4(minC*0.5+maxC*0.5, 1.0); // midpoint
        else if (STYLE==10) iCol = vec4(mix(minC, maxC, 1.0-3.0*k), 1.0); // light to dark
        else if (STYLE==11) iCol = vec4(mix(minC, maxC, 1.0-fract((sumV)*textureScale*0.001*STEP+t.x*30.0)), 1.0); // light/dark banding
        else if (STYLE==12) iCol = vec4(mix(minC, maxC, 1.0-refract((sumV)*textureScale*0.001*STEP+t.x*30.0)), 1.0); // light/dark banding

        else if (STYLE==13) iCol = floor(fract((sumV)*textureScale*0.001*STEP+t.x*30.0)*2.0)==0.0 ? u_Color1 : u_Color2; // concentric bw bands
        else if (STYLE==14) iCol = mix(u_Color1, u_Color2, (refract(sumV*textureScale*0.001*STEP+t.x*30.0)));
        else if (STYLE==15) iCol = mix(texture2D(u_Tex0, proj0(p)), texture2D(u_Tex0, proj0(v)), 0.5); // ghost
        else if (STYLE==16) iCol = vec4(vec3(length(p-v+t)*3.0), 1.0);
        else if (STYLE==17) iCol = mix(texture2D(u_Tex0, proj0(p)), texture2D(u_Tex0, proj0(pix)), dot(normalize(v-p), normalize(pix-p)));
        else if (STYLE==18) iCol = texture2D(u_Tex0, proj0(pix+t)); // pixelated/banding

        else if (STYLE==19) iCol = getCheckerboard4(v+t, textureScale); // checkerboard/distortion
        else if (STYLE==20) iCol = getCheckerboard4(v+t, textureScale); // checkerboard/distortion
        else if (STYLE==21) { float di = distInf(v+t/(0.01*textureScale)); iCol = di<0.05 ? u_Color2 : (fmod(0.01*textureScale/max(1e-10, di), 2.0)<1.0 ? u_Color1 : u_Color2); } // concentric centered fixed bands
        else if (STYLE==22) { float di = distInf(v+t/(0.01*textureScale)); iCol = mix(vec4(0.0, 0.0, 0.0, 1.0), fmod(0.01*textureScale/max(1e-10, di), 2.0)<1.0 ? u_Color1 : u_Color2, clamp(di/0.2-0.05, 0.0, 1.0)); } // concentric centered fixed bands
        else if (STYLE==23) { float di = distInf(v+t/(0.01*textureScale)); iCol = fmod(0.01*textureScale*di, 2.0)<1.0 ? u_Color1 : u_Color2; } // concentric centered fixed bands
        else if (STYLE==24) { float di = distInf(v+t/(0.01*textureScale)); iCol = mix(vec4(0.0, 0.0, 0.0, 1.0), fmod(0.01*textureScale*di, 2.0)<1.0 ? u_Color1 : u_Color2, clamp(di/0.2-0.05, 0.0, 1.0)); } // concentric centered fixed bands

        else if (STYLE==25) iCol = vec4((normalize((dir-t.xy))+1.0)*0.5, 0.5*textureScale*0.01, 1.0); // direction
        else if (STYLE==26) { vec2 nd = (normalize((dir-t.xy))+1.0)*0.5;  iCol = vec4(nd.x, 0.25*textureScale*0.01, nd.y, 1.0); } // direction
        else if (STYLE==27) iCol = vec4(0.75*textureScale*0.01, (normalize((dir-t))+1.0)*0.5, 1.0); // direction
        else if (STYLE==28) iCol = texture2D(u_Tex0, proj0((dir-t)*textureScale*0.01)); // direction mapped to texture
        else if (STYLE==29) iCol = mix(u_Color1, u_Color2, abs(normalize(dir-t)).x); // direction mapped to colors
        else if (STYLE==30) iCol = mix(u_Color1, u_Color2, fmod(floor((t.x+v.x)*textureScale), 2.0)); // direction mapped to colors
        else if (STYLE==31) iCol = mix(u_Color1, u_Color2, fmod(floor((t.y+v.y)*textureScale), 2.0)); // direction mapped to colors

        else if (STYLE==35) iCol = mix(texture2D(u_Tex0, proj0(vec2(v.x, -textureScale*0.01+t.y))), texture2D(u_Tex0, proj0(vec2(v.x, textureScale*0.01+t.y))), (v.y+textureScale*0.01-t.y)/(textureScale*0.02));
        else if (STYLE==36) iCol = mix(texture2D(u_Tex0, proj0(vec2(-textureScale*0.01+t.x, v.y))), texture2D(u_Tex0, proj0(vec2(textureScale*0.01+t.x, v.y))), (v.x+textureScale*0.01-t.x)/(textureScale*0.02));
        else if (STYLE==37) iCol = mix(texture2D(u_Tex0, proj0(vec2(v.x, floor(v.y*textureScale+t.y)/textureScale))), texture2D(u_Tex0, proj0(vec2(v.x, floor(v.y*textureScale)/textureScale+t.y))), fmod(v.y+t.y, textureScale));
        else if (STYLE==38) iCol = vec4(abs(maxC-minC), 1.0);
        else if (STYLE==39) iCol = vec4(abs(minC-maxC), 1.0);
        else if (STYLE==40) iCol = vec4(pow(minC.x/maxC.x, 0.5), pow(minC.y/maxC.y, 0.5), pow(minC.z/maxC.z, 0.5), 1.0);

        if (u_Shadows>0.0) {
            iCol.rgb *= mix(0.25, 1.0, smoothstep(1.0, 1.0-u_Shadows*0.01, insidness));
        }

        if (u_Balance>=0.0) return mix(iCol, inCol, u_Balance*0.01);
        else return vec4((iCol*inCol*min(1.0, -u_Balance*0.02) + iCol*(1.0+u_Balance*0.006)).rgb, inCol.a);
    }
    else {
        return texture2D(u_Tex0, proj0(uv));
    }
    //return texture(u_Tex0, v);
    //return k<0.1 ? vec4(vec3(floor(fract(totColDiff*0.1)*2.0)), 1.0) : texture(u_Tex0, uv);
    //return totValDiff<30.0 ? vec4(vec3(floor(fract(totColDiff*0.1)*2.0)), 1.0) : texture(u_Tex0, uv);
    //return k<0.1 ? (even ? texture(u_Tex0, v): vec4(vec3(getCheckerboard(v)), 1.0)) : texture(u_Tex0, uv);
    //return k<0.4 ? vec4(fract(totColDiff*0.02), 1.0) : texture(u_Tex0, uv);
    //return texture(u_Tex0, uv) + maxV*0.5;
    //return k<0.1 ? vec4(vec3(length(p-uv)*4.0), 1.0) : texture(u_Tex0, uv);
    //return k<0.21 ? vec4(vec3(sumV/maxV)*0.004, 1.0) : texture(u_Tex0, uv);
    //return k<0.21 ? texture(u_Tex0, uv)*mix(0.25, 1.0, smoothstep(0.21, 0.18, k))*vec4(vec3(sumV/maxV)*0.004, 1.0) : texture(u_Tex0, uv);
}

vec4 blob(vec2 uv, vec2 outPos) {

    vec2 pos = (u_ModelTransform * vec3(0.0, 0.0, 1.0)).xy;

    vec4 inCol = texture2D(u_Tex0, proj0(uv));
    vec4 outCol = getColor(inCol, pos, uv);
    if (outCol.a<1.0) outCol = vec4(mix(inCol.rgb, outCol.rgb, outCol.a), inCol.a);

    outCol.a = inCol.a;
    outCol.r = clamp(outCol.r, 0.0, 1.0);
    outCol.g = clamp(outCol.g, 0.0, 1.0);
    outCol.b = clamp(outCol.b, 0.0, 1.0);
    return mix(inCol, outCol, getLocus(uv, inCol, outCol));
}


#include mainWithOutPos(blob)
