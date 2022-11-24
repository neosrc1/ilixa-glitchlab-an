precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include random
#include locuswithcolor_nodep

#define M_PI_2 1.5707963267948966
#define BASIC false

uniform float u_Balance;
uniform float u_Seed;
uniform float u_Regularity;
uniform mat3 u_InverseModelTransform;

float min2(vec2 u) {
    return min(u.x, u.y);
}
float max2(vec2 u) {
    return max(u.x, u.y);
}


float rnd2a(vec2 u) {
    float a = 5.0*fract(dot(u, u.yx+vec2(10.32777, 13.1123)));
    float b = 5.0*fract(dot(vec2(a*u.y, u.x), -u.xy+0.55555));
    return fract(10.1545*a*b-dot(u, u));
}

float rnd2b(vec2 u) {
    float a = 5.001*fract(dot(u, u.yx+vec2(5.5, 4.50)));
    float b = 5.0*fract(dot(vec2(a*u.y, u.x), -u.xy+0.555));
    return fract(10.5*a*b-dot(u, u));
}

float rnd2c(vec2 u) {
    float IR2 = sign(fract(u_Seed*10.0)-0.5) * pow(0.5, floor((100.0-u_Regularity)*0.04));
    float IR1 = fract(pow(0.5, floor((100.0-u_Regularity)*0.04))*floor(fract(u_Seed*40.0)*10.0));
    float a = (5.0+IR1)*fract(dot(u, u.yx+vec2(5.0+IR1, 4.0+IR2)));
    float b = (5.0+IR2)*fract(dot(vec2(a*u.y, u.x), -u.xy+IR1));
    return fract((10.0+IR2)*a*b-dot(u, u));
}

float rnd2(vec2 u) {
    float a = 5.0*fract(dot(u, u.yx+vec2(10.32777, 13.1123))+u_Seed*0.977);
    float b = 5.0*fract(dot(vec2(a*u.y, u.x), -u.xy+0.55555));
    float r1 = fract(10.1545*a*b-dot(u, u));

    float R1 = floor(fract(u_Seed*1.1+0.51)*4.0)/4.0;
    float R2 = floor(fract(u_Seed*4.3)*4.0)/4.0;
    float R3 = floor(fract(u_Seed*23.4)*4.0)/4.0;
    float R4 = floor(fract(u_Seed*71.7)*4.0)/4.0;
    float a2 = (5.0+R4)*fract(dot(u, u.yx+vec2(5.0+R1, 4.0+R2)));
    float b2 = 5.0*fract(dot(vec2(a2*u.y, u.x), -u.xy+0.5+R3/2.0));
    float r2 = fract(10.5*a2*b2-dot(u, u));

    return (fract(u_Seed+u.x*1.2337+u.y*3.23323)>u_Regularity*0.01) ? r1 : r2;
}

float rnd2dir(vec2 u, vec2 dir) {
    //return abs(dir.x)<abs(dir.y) ? 1.0: 0.0;
    return rnd2(2.0*u+1.0+dir);
}

bool getDir(vec2 u, vec2 dir) {
	return rnd2dir(u, dir)<0.5;
}

vec4 getCol(float x, float y) {
    return texture2D(u_Tex0, proj0((u_InverseModelTransform * vec3(x, y, 1.0)).xy));
}

vec4 getCol2(vec2 u) {
    return texture2D(u_Tex0, proj0((u_InverseModelTransform * vec3(u, 1.0)).xy));
}

float getLightness2(vec2 u) {
    vec4 col = texture2D(u_Tex0, proj0((u_InverseModelTransform * vec3(u, 1.0)).xy));
    return (col.r+col.g+col.b)/3.0;
}

bool getGradientDir(vec2 u, vec2 dir) {
    vec2 v = u+0.5+0.5*dir;
    vec2 delta = vec2(0.3, 0.0);
    return abs(getLightness2(v+delta)-getLightness2(v-delta)) + abs(getLightness2(v+delta.yx+delta)-getLightness2(v+delta.yx-delta)) + abs(getLightness2(v-delta.yx+delta)-getLightness2(v-delta.yx-delta)) <
        abs(getLightness2(v+delta.yx)-getLightness2(v-delta.yx)) + abs(getLightness2(v+delta+delta.yx)-getLightness2(v+delta-delta.yx)) + abs(getLightness2(v-delta+delta.yx)-getLightness2(v-delta-delta.yx));
}


vec4 hInterpol(vec2 c, vec2 u) {
    return mix(getCol(c.x, u.y), getCol(c.x+1.0, u.y), u.x-c.x);
}

vec4 vInterpol(vec2 c, vec2 u) {
    return mix(getCol(u.x, c.y), getCol(u.x, c.y+1.0), u.y-c.y);
}

vec4 corner(vec2 c, vec2 u, vec2 u1, vec2 u2) {
    vec2 center = c+0.5 -0.5*(u1+u2);
    vec2 rel = u-center;
    float len = length(rel);
    if (len<1.0) {
        float a = atan(dot(u-center, u2), dot(u-center, u1));
        return mix(getCol2(center+len*u1), getCol2(center+len*u2), a/M_PI_2);
    }
    else {
        if (BASIC) {
            return hInterpol(c, u);
        }
        else {
            float X = abs(u.y-c.y-0.5);
            float Y = abs(u.x-c.x-0.5);
            if (X>Y) return mix(getCol(c.x+0.5-X, u.y), getCol(c.x+0.5+X, u.y), (u.x-c.x-0.5+X)/(2.0*X));
            return mix(getCol(u.x, c.y+0.5-Y), getCol(u.x, c.y+0.5+Y), (u.y-c.y-0.5+Y)/(2.0*Y));
        }
    }
}

vec4 tCorner(vec2 c, vec2 u, vec2 u1, vec2 u2) {
    vec2 center = c+0.5 -0.5*(u1+u2);
    vec2 rel = u-center;
    float len = length(rel);
    if (len<1.0) {
        float a = atan(dot(u-center, u2), dot(u-center, u1));
        return mix(getCol2(center+len*u1), getCol2(center+len*u2), a/M_PI_2);
    }
    else {
        return vec4(0.0);
    }
}

vec4 vCorner(vec2 c, vec2 u, vec2 u1, vec2 u2) {
    vec2 center = c+0.5 -0.5*(u1+u2);
    vec2 rel = u-center;
    float len = length(rel);
    if (len<1.0) {
        float a = atan(dot(u-center, u2), dot(u-center, u1));
        return mix(getCol2(center+len*u1), getCol2(center+len*u2), a/M_PI_2);
    }
    else {
        return vInterpol(c, u);
    }
}

vec4 hCorner(vec2 c, vec2 u, vec2 u1, vec2 u2) {
    vec2 center = c+0.5 -0.5*(u1+u2);
    vec2 rel = u-center;
    float len = length(rel);
    if (len<1.0) {
        float a = atan(dot(u-center, u2), dot(u-center, u1));
        return mix(getCol2(center+len*u1), getCol2(center+len*u2), a/M_PI_2);
    }
    else {
        return hInterpol(c, u);
    }
}


vec4 streak(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec2 c = floor(u);
    vec2 f = u-c;
    vec2 cell = abs(f-0.5);
    float k = max(cell.x, cell.y);

    bool dirBottom = getDir(c, vec2(0.0, -1.0)); // true = horizontal
    bool dirTop = getDir(c, vec2(0.0, 1.0));
    bool dirLeft= getDir(c, vec2(-1.0, 0.0));
    bool dirRight = getDir(c, vec2(1.0, 0.0));

    if (pow(1.0-fract(u_Seed*0.11111), 10.0-u_Regularity*0.09)>0.95) {
        dirBottom = dirTop = false;
        dirLeft = dirRight = true;
    }

    if (rand2relSeeded(c, u_Seed).x+0.5 < abs(u_Balance*0.01)) {
        dirBottom = getGradientDir(c, vec2(0.0, -1.0));
        dirTop = getGradientDir(c, vec2(0.0, 1.0));
        dirLeft= getGradientDir(c, vec2(-1.0, 0.0));
        dirRight = getGradientDir(c, vec2(1.0, 0.0));
        if (u_Balance<0.0) {
            dirTop = !dirTop; dirBottom = !dirBottom; dirLeft = !dirLeft; dirRight = !dirRight;
        }
    }



    vec4 col = vec4(0.0, 1.0, 0.0, 1.0);

    if (dirTop==dirBottom && dirTop==dirLeft && dirTop==dirRight) {
        if (dirTop) {
            col = hInterpol(c, u);
        }
        else {
            col = vInterpol(c, u);
        }
    }
    else if (dirTop && dirBottom && dirLeft && !dirRight) {
        if (BASIC) {
        	col = hInterpol(c, u);
        }
        else {
            col = vec4(0.0, 1.0, 0.0, 1.0);
            float X = c.x+0.5 + abs(u.y-c.y-0.5);
            if (u.x<X) col = mix(getCol(c.x, u.y), getCol(X, u.y), (u.x-c.x)/(X-c.x));
            else {
                float Y = abs(u.x-c.x-0.5);
                col = mix(getCol(u.x, c.y+0.5-Y), getCol(u.x, c.y+0.5+Y), (u.y-c.y-0.5+Y)/(2.0*Y));
            }
            //col = length(u-vec2(c.x+1.0, c.y+0.5))<0.5 ? vInterpol(c, u) : hInterpol(c, u);
        }
    }
    else if (dirTop && dirBottom && !dirLeft && dirRight) {
        if (BASIC) {
        	col = hInterpol(c, u);
        }
        else {
            float X = c.x+0.5 - abs(u.y-c.y-0.5);
            if (u.x>X) col = mix(getCol(X, u.y), getCol(c.x+1.0, u.y), (u.x-X)/(c.x+1.0-X));
            else {
                float Y = abs(u.x-c.x-0.5);
                col = mix(getCol(u.x, c.y+0.5-Y), getCol(u.x, c.y+0.5+Y), (u.y-c.y-0.5+Y)/(2.0*Y));
            }
        }
    }
    else if (dirTop && !dirBottom && dirLeft && dirRight) {
        col = hCorner(c, u, vec2(0.0, 1.0), vec2(-1.0, 0.0));
    }
    else if (!dirTop && dirBottom && dirLeft && dirRight) {
        col = hCorner(c, u, vec2(-1.0, 0.0), vec2(0.0, -1.0));
    }
    else if (dirTop && dirBottom && !dirLeft && !dirRight) {
        if (BASIC) {
            col = hInterpol(c, u);
        }
        else {
            float X = abs(u.y-c.y-0.5);
            float Y = abs(u.x-c.x-0.5);
        	if (X>Y) col = mix(getCol(c.x+0.5-X, u.y), getCol(c.x+0.5+X, u.y), (u.x-c.x-0.5+X)/(2.0*X));
            else col = mix(getCol(u.x, c.y+0.5-Y), getCol(u.x, c.y+0.5+Y), (u.y-c.y-0.5+Y)/(2.0*Y));
        }
    }
    else if (!dirTop && dirBottom && dirLeft && !dirRight) {
        col = corner(c, u, vec2(0.0, -1.0), vec2(1.0, 0.0));
    }
    else if (dirTop && !dirBottom && dirLeft && !dirRight) {
        col = corner(c, u, vec2(1.0, 0.0), vec2(0.0, 1.0));
    }
    else if (!dirTop && dirBottom && !dirLeft && dirRight) {
        col = corner(c, u, vec2(-1.0, 0.0), vec2(0.0, -1.0));
    }
    else if (dirTop && !dirBottom && !dirLeft && dirRight) {
        col = corner(c, u, vec2(0.0, 1.0), vec2(-1.0, 0.0));
    }
   	else if (!dirTop && !dirBottom && dirLeft && !dirRight) {
        if (rnd2(c)<0.5) col = vCorner(c, u, vec2(0.0, -1.0), vec2(1.0, 0.0));
        else col = vCorner(c, u, vec2(1.0, 0.0), vec2(0.0, 1.0));
    }
   	else if (!dirTop && !dirBottom && !dirLeft && dirRight) {
        if (rnd2(c)<0.5) col = vCorner(c, u, vec2(0.0, 1.0), vec2(-1.0, 0.0));
        else col = vCorner(c, u, vec2(-1.0, 0.0), vec2(0.0, -1.0));
    }
   	else if (dirTop && !dirBottom && !dirLeft && !dirRight) {
        if (BASIC) {
        	col = vInterpol(c, u);
        }
        else {
            float Y = c.y+0.5 + abs(u.x-c.x-0.5);
            if (u.y<Y) col = mix(getCol(u.x, c.y), getCol(u.x, Y), (u.y-c.y)/(Y-c.y));
            else {
                float X = abs(u.y-c.y-0.5);
                col = mix(getCol(c.x+0.5-X, u.y), getCol(c.x+0.5+X, u.y), (u.x-c.x-0.5+X)/(2.0*X));
            }
        }
    }
   	else if (!dirTop && dirBottom && !dirLeft && !dirRight) {
        if (BASIC) {
        	col = vInterpol(c, u);
        }
        else {
            float Y = c.y+0.5 - abs(u.x-c.x-0.5);
            if (u.y>Y) col = mix(getCol(u.x, Y), getCol(u.x, c.y+1.0), (u.y-Y)/(c.y+1.0-Y));
            else {
                float X = abs(u.y-c.y-0.5);
                col = mix(getCol(c.x+0.5-X, u.y), getCol(c.x+0.5+X, u.y), (u.x-c.x-0.5+X)/(2.0*X));
            }
        }
    }
    else
        if (!dirTop && !dirBottom && dirLeft && dirRight) {
        vec4 col1 = tCorner(c, u, vec2(1.0, 0.0), vec2(0.0, 1.0));
        vec4 col2 = tCorner(c, u, vec2(0.0, -1.0), vec2(1.0, 0.0));
        vec4 col3 = tCorner(c, u, vec2(-1.0, 0.0), vec2(0.0, -1.0));
        vec4 col4 = tCorner(c, u, vec2(0.0, 1.0), vec2(-1.0, 0.0));
        mat4 cols = mat4(col1, col2, col3, col4);
        float r = rnd2(c);
        for(int i=0; i<5; ++i) {
            int i1 = int(floor(r*4.0));
            int i2 = i1+1; if (i2>=4) i2 = 0;
            vec4 tmp = cols[i1];
            cols[i1] = cols[i2];
            cols[i2] = tmp;
            r *= 0.25;
        }
        for(int i=0; i<4; ++i) {
            col = cols[i];
            if (col.a==1.0) break;
        }
    }

    vec4 bkgCol = texture2D(u_Tex0, proj0(pos));
    return mix(bkgCol, col, getLocus(pos, bkgCol, col));
}

#include mainWithOutPos(streak)
