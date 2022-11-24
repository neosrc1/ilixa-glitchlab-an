precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform int u_Count; // levels
uniform float u_Regularity;
uniform float u_Distribution;
uniform int u_Types; // number of types
uniform int u_Type[32]; // types used



#define THIRD 0.33333333
#define TWO_THIRDS 0.666666666

bool inThirds(float d) {
    return d>=THIRD && d<=TWO_THIRDS;
}

bool inThirdCircle(float cx, float cy, vec2 u) {
 	return length(vec2(cx, cy)-u)<=0.16666666 ;
}

bool in2ThirdCircle(float cx, float cy, vec2 u) {
 	return length(vec2(cx, cy)-u)<=0.33333333 ;
}

bool truchetTile(vec2 u, int type) {
    if (type==1) return inThirds(length(vec2(0.0, 1.0) - u)) || inThirds(length(vec2(1.0, 0.0) - u));
   	//else if (type==2) return inThirds(u.x) || inThirds(u.y);
   	else if (type==2) return !in2ThirdCircle(0.0, 0.0, u) && !in2ThirdCircle(1.0, 0.0, u) && !in2ThirdCircle(0.0, 1.0, u) && !in2ThirdCircle(1.0, 1.0, u);
    else if (type==3) return inThirdCircle(0.0, 0.5, u) || inThirdCircle(1.0, 0.5, u) || inThirdCircle(0.5, 0.0, u) || inThirdCircle(0.5, 1.0, u);
    else return inThirds(length(u)) || inThirds(length(vec2(1.0, 1.0) - u));
}

int hash(int a, int b) {
    return (a + b) * (a + b + 1) / 2 + a;
}

int hashmore(int i, int j) {
    float x = float(i);
    float y = float(j);
    int h = int(fract(sin(x*12.9898+y*78.233) * (x/(fmod(y, 1000.0)+1.0)+458.5453))*1000.0);
    if (u_Regularity==0.0) return h;
    return (fmod(float(hash(i,j)), 100.0)>=u_Regularity) ? h : (i+j)*50;
}

int getType(int i, int j) {
    return int(u_Type[int(fmod(float(hashmore(i, j)), float(u_Types)))]);
}

int getLevel(int i, int j) {
    int level = u_Count;
    float d = u_Distribution;
    float k = pow(100.0/d, 1.0/float(level));
    float div = pow(2.0, float(level));
    while (level>=1) {
        vec2 F = vec2(float(i-(i<0?int(div)-1:0)), float(j-(j<0?int(div)-1:0)))/div;
        int I = int(F.x);
        int J = int(F.y);
	    if (fmod(float(hashmore(I+11, J+14)), 100.0) > d) return level;
        d /= k;
        div /= 2.0;
        --level;
    }
    return 0;
}

bool inWing(vec2 pos, vec2 center, float ox, float oy, float r2) {
    vec2 delta = pos - vec2(center.x+ox, center.y+oy);
    return dot(delta, delta) < r2;
}

int minWing(int wing, vec2 pos, int i, int j) {
    int mLevel = getLevel(i, j);
    int W = wing;
    //for(int level = wing-1; level>=mLevel; --level) {
    for(int level = mLevel; level<W; ++level) {
        float len = 1.0;
        float halflen = len/2.0;
        float exp = pow(2.0, float(level));
        vec2 center = vec2(floor(float(i)/exp) + halflen, floor(float(j)/exp) + halflen);
        float radius = len/3.0;
		vec2 ppos = pos / exp; //float(1<<level);

        if (max(abs(ppos.x-center.x), abs(ppos.y-center.y)) <= halflen+radius) {

            //float radius2 = radius*radius;
            vec2 rel = ppos-center;
            vec2 wingc = sign(rel)*halflen;
            if (wingc.x!=0.0 && wingc.y!=0.0) {
                vec2 delta = rel-wingc;
                //wing = dot(delta, delta) < radius2 ? level :wing;
                if (length(delta) < radius) return level;
            }
            /*wing = (inWing(ppos, center, -halflen, -halflen, radius2)
                || inWing(ppos, center, -halflen, halflen, radius2)
                || inWing(ppos, center, halflen, -halflen, radius2)
                || inWing(ppos, center, halflen, halflen, radius2) ) ? level : wing;*/

            /*wing = ((length(ppos - (center+vec2(-halflen, -halflen))) < radius)
    || (length(ppos - (center+vec2(-halflen, halflen))) < radius)
    || (length(ppos - (center+vec2(halflen, -halflen))) < radius)
    || (length(ppos - (center+vec2(halflen, halflen))) < radius) ) ? level : wing;*/
            /*
            if (length(ppos - (center+vec2(-halflen, -halflen))) < radius) return level;
            else if (length(ppos - (center+vec2(-halflen, halflen))) < radius) return level;
            else if (length(ppos - (center+vec2(halflen, -halflen))) < radius) return level;
            else if (length(ppos - (center+vec2(halflen, halflen))) < radius) return level;*/
       	}
    }

    return wing;
}

vec4 truchet(vec2 pos, vec2 outPos) {
    pos = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec2 ipos = floor(pos);
    int i = int(ipos.x);
    int j = int(ipos.y);

    int level = getLevel(i, j);
    int exp = int(pow(2.0, float(level)));
    int I = (i-(i<0?exp-1:0))/exp;
    int J = (j-(j<0?exp-1:0))/exp;
    int type = getType(I, J);
    float scaling = pow(2.0, float(level)); //float(1 << level);
    bool negative = (level - (level/2)*2 == 1); //level%2==1;

    vec2 scPos = pos/scaling;
    vec2 relPos = fract(scPos);
    /*vec2 absScPos = vec2(10000.0, 10000.0);//ceil(abs(scPos));
    //vec2 relPos = fract(scPos+absScPos);//vec2(pos.x<0.0 ? fract(absScPos.x + scPos.x) : fract(scPos.x), pos.y<0.0 ? fract(pos.y/scaling) : fract(absScPos.y + scPos.y)); //fract(pos/scaling);
    vec2 relPos = vec2(pos.x<0.0 ? fract(scPos.x+16.0) : fract(scPos.x), pos.y<0.0 ? 0.0 : fract(absScPos.y + scPos.y)); //fract(pos/scaling);
    */

    float k = truchetTile(relPos, type) ? 1.0 : 0.0;
    if (negative) k = 1.0-k;

    // test wing
    int wing = level;
    if (level>=1 && max(abs(relPos.x-0.5), abs(relPos.y-0.5)) > 0.333333) {
        int N = int(pow(2.0, float(level-1))); //(1 << (level-1));
        for(int jj=j-N; jj<=j+N; ++jj) {
            for(int ii=i-N; ii<=i+N; ++ii) {
                wing = minWing(wing, pos, ii, jj);
            }
        }
        if (wing<level) {
            k = (wing - (wing/2)*2)==0 ? 0.0 : 1.0; //k = wing%2==0 ? 0.0 : 1.0;
        }

    }

    return mix(u_Color1, u_Color2, k);

}

#include mainWithOutPos(truchet)
