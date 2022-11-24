precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform float u_ColorScheme;
uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;

uniform float u_Gamma;
uniform float u_Shadows;
uniform float u_Specular;
uniform float u_SurfaceSmoothness;
uniform float u_NormalSmoothing;
uniform float u_LSDistance;
uniform mat4 u_LightSourceTransform;
uniform vec4 u_AmbientColor;
uniform vec4 u_SourceColor;


float height(float intensity, vec4 color) {
    return intensity*0.04* ((color.r + color.g + color.b)/3.0 - 0.5);
}

vec4 applyLighting(vec4 baseColor, float fromSource, float specular) {
    vec3 sumRGB = u_AmbientColor.rgb + u_SourceColor.rgb;
    float maxLum = max(max (sumRGB.r, sumRGB.g), sumRGB.b);
    if (maxLum == 0.0) return vec4(0.0, 0.0, 0.0, 1.0);

    vec3 color = (baseColor.rgb*u_AmbientColor.rgb + baseColor.rgb*u_SourceColor.rgb*fromSource + u_SourceColor.rgb*specular) / maxLum;

    float lum = (color.r+color.g+color.b)/3.0;
    if (lum>0.0 && u_Gamma!=0.0) {
        float gammaCorrectedLum = pow(lum, pow(1.02, -u_Gamma));
        color = color * gammaCorrectedLum/lum;
    }

    return clamp(vec4(color, baseColor.a), 0.0, 1.0);
}

vec4 getBackground(vec2 pos) {
    return vec4(0.0, 0.0, 0.0, 1.0);

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

    vec3 lightPos = (u_LightSourceTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

//    if (dot(dir, lightPos-cameraPos)>length(lightPos-cameraPos)*0.99) return vec4(1.0, 1.0, 1.0, 1.0); // show light source

    float k1 = 0.0;
    float k2 = 100000000.0;

    if (dir.x!=0.0) {
        float s = sign(dir.x);
        float k3 = (-s*ratio-cameraPos.x)/dir.x;
        float k4 = (s*ratio-cameraPos.x)/dir.x;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    if (dir.y!=0.0) {
        float s = sign(dir.y);
        float k3 = (-s-cameraPos.y)/dir.y;
        float k4 = (s-cameraPos.y)/dir.y;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    float maxZ2 = maxZ+0.0001; // prevent flickering on edge case
    if (dir.z!=0.0) {
        float s = sign(dir.z);
        float k3 = (-s*maxZ2-cameraPos.z)/dir.z;
        float k4 = (s*maxZ2-cameraPos.z)/dir.z;
        k1 = max(k1, k3);
        k2 = min(k2, k4);
    }

    if (k1>k2) return getBackground(pos); //backgroundColor;

    float k = k1;
    vec3 p = cameraPos + k*dir;

    vec4 color = backgroundColor;
    float h = 0.0;
    float dz = 0.0;
    float prevDz;
    vec4 prevColor = vec4(0.0, 0.0, 0.0, 1.0);
    float prevH;
    bool stop;
    do {
        prevColor = color;
        prevDz = dz;
        prevH = h;

        color = texture2D(u_Tex0, proj0(p.xy));
        h = height(intensity, color);
        dz = p.z-h;
        if (k==k1 && dz<0.0) {
            return texture2D(u_Tex0, proj0(p.xy));
        }

        p += step;
        k += dk;
        stop = dz==0.0 || (k!=k1 && sign(dz)==-sign(prevDz));
    } while (k<=k2 && !stop);


//    return vec4(k1, k2, k1>k2 ? 0.25 : 0.75, 1.0);
    stop = stop || abs(dz)<dk;


    if (!stop) return getBackground(pos); //return backgroundColor;

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
    float specular = 0.0;
    float shadowing = u_SourceColor.r + u_SourceColor.g + u_SourceColor.b;
    if (shadowing!=0.0) {
        vec3 intersection = p;//mix(p-step, p, kk);
//        float deltaX = dk*u_Gamma;//*0.5;//dk*2.0;
//        float deltaY = dk*u_Gamma;//*0.5;//dk*2.0;
        float deltaX = 0.002;//dk*0.5;//dk*2.0;
        float deltaY = 0.002;//dk*0.5;//dk*2.0;
        float dzdx = 0.0;
        float dzdy = 0.0;
        int maxNormalIter = 6;

        float N = 1.0 + ceil(u_NormalSmoothing/20.0);
        float bx = 0.0005 + u_NormalSmoothing*0.0001;
        float sx = N>=2.0 ? bx/(N-1.0) : 0.0;

        for(int i = 0; i<int(N); ++i) {
            float deltaX = bx+float(i)*sx;
            dzdx += (height(intensity, texture2D(u_Tex0, proj0(vec2(intersection.x+deltaX, intersection.y))))
                    - height(intensity, texture2D(u_Tex0, proj0(vec2(intersection.x-deltaX, intersection.y)))));
        }

        dzdx /= N;
        deltaX = bx+(N-1.0)/2.0*sx;

        float by = 0.0005 + u_NormalSmoothing*0.0001;
        float sy = N>=2.0 ? by/(N-1.0) : 0.0;
        for(int i = 0; i<int(N); ++i) {
            float deltaY = by+float(i)*sy;
            dzdy = (height(intensity, texture2D(u_Tex0, proj0(vec2(intersection.x, intersection.y+deltaY))))
                   - height(intensity, texture2D(u_Tex0, proj0(vec2(intersection.x, intersection.y-deltaY)))));
        }
        dzdy /= N;
        deltaY = by+(N-1.0)/2.0*sy;


        vec3 normal = normalize(vec3(-2.0*deltaY*dzdx, -2.0*deltaX*dzdy, deltaX*deltaY));

        lighting = (dot(lightDir, normal)+1.0)/2.0;
        if (u_SurfaceSmoothness<100.0) {
            if (lighting<0.5) lighting = pow(lighting*2.0, 100.0/u_SurfaceSmoothness) / 2.0;
            else lighting = pow((lighting-0.5)*2.0, 0.01*u_SurfaceSmoothness) / 2.0 + 0.5;
        }

        if (u_Specular!=0.0) {
            vec3 reflectLightDir = reflect(lightDir, normal);
            specular = pow(clamp(dot(dir, reflectLightDir), 0.0, 1.0), 10.0-u_Specular*0.1);
        }
    }

    float shadows = u_Shadows*0.01;
    if (shadowing!=0.0 && shadows > 0.0 && intensity!=0.0) {
        p = p-2.0*step; // avoid intersecting immediately
        vec3 lightStep = lightDir * dk;

        k1 = 0.0;
        float k2 = length(lightVec);

        if (lightDir.x!=0.0) {
            float s = sign(lightDir.x);
            float k3 = (-s*ratio-p.x)/lightDir.x;
            float k4 = (s*ratio-p.x)/lightDir.x;
            if (k4>0.0) k2 = min(k2, k4);
            if (k3>0.0) k2 = min(k2, k3);
        }

        if (lightDir.y!=0.0) {
            float s = sign(lightDir.y);
            float k3 = (-s-p.y)/lightDir.y;
            float k4 = (s-p.y)/lightDir.y;
            if (k4>0.0) k2 = min(k2, k4);
            if (k3>0.0) k2 = min(k2, k3);
        }

        float maxZ2 = maxZ+0.0001; // prevent flickering on edge case
        if (lightDir.z!=0.0) {
            float s = sign(lightDir.z);
            float k3 = (-s*maxZ2-p.z)/lightDir.z;
            float k4 = (s*maxZ2-p.z)/lightDir.z;
            if (k4>0.0) k2 = min(k2, k4);
            if (k3>0.0) k2 = min(k2, k3);
        }

        k = 0.0;

        h = 0.0;
        dz = 0.0;
        stop = false;

        do {
            prevDz = dz;
            prevH = h;

            h = height(intensity, texture2D(u_Tex0, proj0(p.xy)));
            dz = p.z-h;

            p += lightStep;
            k += dk;
            stop = dz==0.0 || (k!=k1 && sign(dz)==-sign(prevDz));
        } while (k<=k2 && !stop);

        if (stop) {
            lighting = min(1.0-shadows, lighting);
            specular = 0.0;
        }
    }

    color = applyLighting(color, lighting, specular);

    return color;
}

#include mainWithOutPos(planar)
