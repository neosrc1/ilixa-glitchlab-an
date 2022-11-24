precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include locuswithcolor_nodep

uniform float u_Count;
uniform float u_Length;
uniform float u_Balance;
uniform mat3 u_InverseModelTransform;

vec4 streak(vec2 pos, vec2 outPos) {
    vec4 col = texture2D(u_Tex0, proj0(pos));

    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    float ratio = u_Tex0Dim.x/u_Tex0Dim.y;
    float scale = length(vec2(u_ModelTransform[0][0], u_ModelTransform[1][0]));
    float l = u_Length*0.015 * max(1.0, ratio) * scale;
    float b = 0.2 * u_Balance*0.01 * scale;
    float pixel = 2.0/u_Tex0Dim.y * scale;

    if (abs(u.x)<l && abs(u.y)<1.0+abs(b)) {
        float ya = -1.0;
        float yb = 1.0;
        if (b!=0.0) {
            vec2 p = vec2(u.x, ya);
            vec2 ip = (u_InverseModelTransform * vec3(p, 1.0)).xy;
            vec4 c = texture2D(u_Tex0, proj0(ip));
            float value = (c.r+c.g+c.b);
            float threshold = 1.5;
            float dt = threshold * pixel/b;
            float dir = -sign(b * (value-threshold));
            //p.y  += dir*b;
            while (dir!=0.0 && abs(p.y-ya)<abs(b)) {
                p.y += dir*pixel;
                ip = (u_InverseModelTransform * vec3(p, 1.0)).xy;
                c = texture2D(u_Tex0, proj0(ip));
                value = (c.r+c.g+c.b);
                float newdir = -sign(b * (value-threshold));
                if (dir!=newdir) dir = 0.0;
                threshold -= dir*dt;
            }
            ya = p.y;

            p = vec2(u.x, yb);
            ip = (u_InverseModelTransform * vec3(p, 1.0)).xy;
            c = texture2D(u_Tex0, proj0(ip));
            value = (c.r+c.g+c.b);
            threshold = 1.5;
            dt = threshold * pixel/b;
            dir = sign(b * (value-threshold));
            //p.y  += dir*b;
            while (dir!=0.0 && abs(p.y-yb)<abs(b)) {
                p.y += dir*pixel;
                ip = (u_InverseModelTransform * vec3(p, 1.0)).xy;
                c = texture2D(u_Tex0, proj0(ip));
                value = (c.r+c.g+c.b);
                float newdir = sign(b * (value-threshold));
                if (dir!=newdir) dir = 0.0;
                threshold += dir*dt;
            }
            yb = p.y;
        }

//        if (abs(u.y-ya)<pixel*1.7) return vec4(1.0, 0.0, 0.0, 1.0);

        if (u.y>=ya && u.y<=yb) {
            float stride = (yb-ya)/u_Count; //2.0/u_Count;
            float y = u.y-ya;//+1.0;
            float y1 = floor(y/stride)*stride + ya;//-1.0;
            float y2 = y1+stride;
            vec2 p1 = (u_InverseModelTransform * vec3(u.x, y1, 1.0)).xy;
            vec2 p2 = (u_InverseModelTransform * vec3(u.x, y2, 1.0)).xy;

            vec4 outColor = mix(texture2D(u_Tex0, proj0(p1)), texture2D(u_Tex0, proj0(p2)), (u.y-y1)/stride);
            float locIntensity = getLocus(pos, col, outColor);
            return mix(col, outColor, locIntensity);

            //        vec2 p1 = (u_InverseModelTransform * vec3(u.x, -1.0, 1.0)).xy;
            //        vec2 p2 = (u_InverseModelTransform * vec3(u.x, 1.0, 1.0)).xy;
            //        return mix(texture2D(u_Tex0, proj0(p1)), texture2D(u_Tex0, proj0(p2)), (u.y+1.0)*0.5);
        }
    }
    return col;


}

#include mainWithOutPos(streak)
