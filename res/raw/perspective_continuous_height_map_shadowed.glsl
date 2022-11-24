precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include tex(1)

uniform float u_Intensity;
uniform float u_ColorScheme;
uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;

uniform float u_Shadows;
uniform float u_LSDistance;
uniform mat4 u_LightSourceTransform;



float height(float intensity, vec4 color) {
    return intensity*0.04* ((color.r + color.g + color.b)/3.0 - 0.5);
}

vec4 planar(vec2 pos, vec2 outPos) {
    float intensity = getMaskedParameter(u_Intensity, outPos);
    vec4 backgroundColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = normalize(vec3(pos.x, pos.y, -1.0));
    dir = mat3(u_InverseModel3DTransform) * dir;

    float maxZ = abs(intensity)*0.02;
    float ratio = (u_Tex0Dim.x/u_Tex0Dim.y);
    float dk = 2.0/u_Tex0Dim.y;
    vec3 step = dir * dk;
    bool heightMap = u_Tex1Transform[2][2]!=0.0;

    vec3 lightPos = (u_LightSourceTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;


//    if (dot(dir, lightPos-cameraPos)>length(lightPos-cameraPos)*0.99) return vec4(1.0, 1.0, 1.0, 1.0); // show light source


    float k1 = 0.0;
    float k2 = 100000000.0;
    
    if (dir.x>0.0) {
        float k3 = (-ratio-cameraPos.x)/dir.x;
        float k4 = (ratio-cameraPos.x)/dir.x;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }
    else if (dir.x<0.0) {
        float k3 = (ratio-cameraPos.x)/dir.x;
        float k4 = (-ratio-cameraPos.x)/dir.x;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }
    
    if (dir.y>0.0) {
        float k3 = (-1.0-cameraPos.y)/dir.y;
        float k4 = (1.0-cameraPos.y)/dir.y;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }
    else if (dir.y<0.0) {
        float k3 = (1.0-cameraPos.y)/dir.y;
        float k4 = (-1.0-cameraPos.y)/dir.y;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    float maxZ2 = maxZ+0.0001; // prevent flickering on edge case
    if (dir.z>0.0) {
        float k3 = (-maxZ2-cameraPos.z)/dir.z;
        float k4 = (maxZ2-cameraPos.z)/dir.z;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }
    else if (dir.z<0.0) {
        float k3 = (maxZ2-cameraPos.z)/dir.z;
        float k4 = (-maxZ2-cameraPos.z)/dir.z;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    if (k1>k2) return backgroundColor;

    float k = k1;
    vec3 p = cameraPos + k*dir;

    vec4 color = backgroundColor;
    float h = 0.0;
    float dz = 0.0;
    float prevDz;
    vec4 prevColor = vec4(0.0, 0.0, 0.0, 1.0);
    float prevH;
    bool stop;
    if (heightMap) {
        do {
            prevDz = dz;
            prevH = h;

            h = height(intensity, texture2D(u_Tex1, proj1(p.xy)));
            dz = p.z-h;

            p += step;
            k += dk;
            stop = dz==0.0 || (k!=k1 && sign(dz)==-sign(prevDz));
        } while (k<=k2 && !stop);
        vec2 pp = (p-step).xy;
        color = texture2D(u_Tex0, proj0(pp));
        prevColor = texture2D(u_Tex0, proj0((pp-step.xy)));
    }
    else {
        do {
            prevColor = color;
            prevDz = dz;
            prevH = h;

            color = texture2D(u_Tex0, proj0(p.xy));
            h = height(intensity, color);
            dz = p.z-h;

            p += step;
            k += dk;
            stop = dz==0.0 || (k!=k1 && sign(dz)==-sign(prevDz));
        } while (k<=k2 && !stop);
    }

//    return vec4(k1, k2, k1>k2 ? 0.25 : 0.75, 1.0);
    stop = stop || abs(dz)<dk;


    if (!stop) return backgroundColor;

    float kk = (dz==0.0 || k1+dk>k2) ? 1.0 : abs(prevDz)/(abs(dz)+abs(prevDz));
    float hh = mix(prevH, h, kk);
    float hRatio = maxZ==0.0 ? 1.0 : hh/maxZ;
    if (u_ColorScheme <=50.0) {
        float darken = 1.0 + u_ColorScheme*0.02*(hh/maxZ);
        color = mix(prevColor, color, kk) * vec4(darken, darken, darken, 1.0);
    }
    else {
        float darken = 1.0 + (hh/maxZ);
        float kkk = (u_ColorScheme-50.0)*0.02;
        vec4 col = mix(prevColor, color, kk) * vec4(darken, darken, darken, 1.0);
        color = mix(col, vec4(darken*0.5, darken*0.5, darken*0.5, 1.0), kkk);
    }

    vec3 lightVec = lightPos - p;
    vec3 lightDir = normalize(lightVec);

    float lighting = 1.0;
    float shadowing = 1.0;
    if (shadowing!=0.0) {
        vec3 intersection = p;//mix(p-step, p, kk);
        float delta = dk*0.5;//dk*2.0;
        float dzdx = (height(intensity, texture2D(u_Tex0, proj0(vec2(intersection.x+delta, intersection.y))))
                - height(intensity, texture2D(u_Tex0, proj0(vec2(intersection.x-delta, intersection.y)))));
        float dzdy = (height(intensity, texture2D(u_Tex0, proj0(vec2(intersection.x, intersection.y+delta))))
                               - height(intensity, texture2D(u_Tex0, proj0(vec2(intersection.x, intersection.y-delta)))));
//        vec3 ux = vec3(2.0*delta, 0.0, dzdx);
//        vec3 uy = vec3(0.0, 2.0*delta, dzdy);
//        vec3 normal = -normalize(vec3(-2.0*delta*dzdx, -2.0*delta*dzdy, -delta*delta));
        vec3 normal = normalize(vec3(-2.0*delta*dzdx, -2.0*delta*dzdy, delta*delta));
//        return vec4(
//            (normal.x<0.0 ? 0.25 : 0.75) + normal.x*0.25,
//            (normal.y<0.0 ? 0.25 : 0.75) + normal.y*0.25,
//            (normal.z<0.0 ? 0.25 : 0.75) + normal.z*0.25,
//        1.0);
        //vec3 normal = -normalize(cross(ux, uy));
//        if (dot(normal, dir)>0.0) normal = -normal;
        lighting = (1.0 + shadowing*dot(lightDir, normal)) / (1.0+shadowing);
    }

//    float tt = color.r;
//    color.r = color.g;
//    color.g = tt;

    float shadows = u_Shadows*0.01;
    if (shadows > 0.0 && intensity!=0.0) {
        p = p-2.0*step; // avoid intersecting immediately
//        p.z = -p.z;
//        vec3 lightPos = vec3(2.0, 4.0, -u_LSDistance);
        vec3 lightStep = lightDir * dk;
//        p += lightStep; k+=dk;

        k1 = 0.0;
        float k2 = length(lightVec);

        if (lightDir.x>0.0) {
            float k3 = (-ratio-p.x)/lightDir.x;
            float k4 = (ratio-p.x)/lightDir.x;
//            k1 = max(k1, k3);
            if (k4>0.0) k2 = min(k2, k4);
            if (k3>0.0) k2 = min(k2, k3);
        }
        else if (dir.x<0.0) {
            float k3 = (ratio-p.x)/lightDir.x;
            float k4 = (-ratio-p.x)/lightDir.x;
//            k1 = max(k1, k3);
            if (k4>0.0) k2 = min(k2, k4);
            if (k3>0.0) k2 = min(k2, k3);
        }

        if (dir.y>0.0) {
            float k3 = (-1.0-p.y)/lightDir.y;
            float k4 = (1.0-p.y)/lightDir.y;
//            k1 = max(k1, k3);
            if (k4>0.0) k2 = min(k2, k4);
            if (k3>0.0) k2 = min(k2, k3);
        }
        else if (dir.y<0.0) {
            float k3 = (1.0-p.y)/lightDir.y;
            float k4 = (-1.0-p.y)/lightDir.y;
//            k1 = max(k1, k3);
            if (k4>0.0) k2 = min(k2, k4);
            if (k3>0.0) k2 = min(k2, k3);
        }

        float maxZ2 = maxZ+0.0001; // prevent flickering on edge case
        if (dir.z>0.0) {
            float k3 = (-maxZ2-p.z)/lightDir.z;
            float k4 = (maxZ2-p.z)/lightDir.z;
//            k1 = max(k1, k3);
            if (k4>0.0) k2 = min(k2, k4);
            if (k3>0.0) k2 = min(k2, k3);
        }
        else if (dir.z<0.0) {
            float k3 = (maxZ2-p.z)/lightDir.z;
            float k4 = (-maxZ2-p.z)/lightDir.z;
//            k1 = max(k1, k3);
            if (k4>0.0) k2 = min(k2, k4);
            if (k3>0.0) k2 = min(k2, k3);
        }

//        if (k1>k2) {
//            color.b = 1.0;
//            return color;
//        }

//        lightStep = vec3(dk, dk, -dk);
//        k2 = 1.0;
        k = 0.0;

        h = 0.0;
        dz = 0.0;
        stop = false;
        if (heightMap) {
            do {
                prevDz = dz;
                prevH = h;

                h = height(intensity, texture2D(u_Tex1, proj1(p.xy)));
                dz = p.z-h;

                p += lightStep;
                k += dk;
                stop = dz==0.0 || (k!=k1 && sign(dz)==-sign(prevDz));
            } while (k<=k2 && !stop);
        }
        else {
            do {
                prevDz = dz;
                prevH = h;

                h = height(intensity, texture2D(u_Tex0, proj0(p.xy)));
                dz = p.z-h;

                p += lightStep;
                k += dk;
                stop = dz==0.0 || (k!=k1 && sign(dz)==-sign(prevDz));
            } while (k<=k2 && !stop);
        }
        if (stop) {
            lighting = min(1.0-shadows, lighting);
        }
    }

    color = vec4(color.rgb * lighting, color.a);


    return color;
}


#include mainWithOutPos(planar)