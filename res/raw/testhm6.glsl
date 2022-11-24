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

    vec3 cameraPos = vec3(0.0, 0.0, 1.0);
    vec3 dir = vec3(pos.x, pos.y, -1.0);
    dir = (dir/length(dir));

    float maxZ = intensity*0.02;
    float ratio = (u_Tex0Dim.x/u_Tex0Dim.y);
    float dk = 0.04;
    vec3 step = dir * dk;

    float k1 = 0.0;
    float k2 = 2.0;

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

        p += step;
        k += dk;
        stop = abs(dz) < 0.01;
    } while (k<=k2 && !stop);

    if (!stop) return backgroundColor;
    else {
        return color;
    }

}


#include mainWithOutPos(planar)
