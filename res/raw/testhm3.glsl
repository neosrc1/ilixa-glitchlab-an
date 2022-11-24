precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Intensity;
uniform float u_ColorScheme;
uniform mat4 u_Model3DTransform;
uniform mat4 u_InverseModel3DTransform;


float height(float intensity, vec4 color) {
    return intensity*0.04* ((color.r + color.g + color.b)/3.0 - 0.5);
}

vec4 planar(vec2 pos, vec2 outPos) {
    float intensity = getMaskedParameter(u_Intensity, outPos);
    vec4 backgroundColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 cameraPos = (u_InverseModel3DTransform * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 dir = vec3(pos.x, pos.y, -1.0);
    dir = mat3(u_InverseModel3DTransform) * (dir/length(dir));

    float maxZ = intensity*0.02;
    float ratio = (u_Tex0Dim.x/u_Tex0Dim.y);
    float dk = 0.02;
    vec3 step = dir * dk;

    float k1 = 0.0;
    float k2 = 2.0;

    float k = k1;
    vec3 p = cameraPos + k*dir;

    vec4 color = backgroundColor;
    float h = 0.0;
    float dz = 0.0;
    float prevDz;
    vec4 prevColor;
    float prevH;
    bool stop;

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


//    return vec4(k1, k2, k1>k2 ? 0.25 : 0.75, 1.0);
    stop = stop || abs(dz)<dk;

    if (!stop) return backgroundColor;
    else {
        float kk = (dz==0.0 || k1+dk>k2) ? 1.0 : abs(prevDz)/(abs(dz)+abs(prevDz));
        float hh = mix(prevH, h, kk);
        if (u_ColorScheme <=50.0) {
            float darken = 1.0 + u_ColorScheme*0.02*(hh/maxZ);
            return mix(prevColor, color, kk) * vec4(darken, darken, darken, 1.0);
        }
        else {
            float darken = 1.0 + (hh/maxZ);
            float kkk = (u_ColorScheme-50.0)*0.02;
            vec4 col = mix(prevColor, color, kk) * vec4(darken, darken, darken, 1.0);
            return mix(col, vec4(darken*0.5, darken*0.5, darken*0.5, 1.0), kkk);
        }
    }

}


#include mainWithOutPos(planar)
