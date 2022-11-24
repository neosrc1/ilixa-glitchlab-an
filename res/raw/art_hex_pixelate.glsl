precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include locuswithcolor_nodep
#include hexagon

uniform vec4 u_Color1;
uniform float u_Thickness;
uniform float u_Pixelate;

uniform float u_Brightness;
uniform float u_Saturation;

uniform mat3 u_InverseModelTransform;

vec4 hex(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;

    vec4 hex = hexPolarCoords(u);
    vec4 outCol = u_Color1;
    vec2 absCoord;
    if (hex.y>u_Thickness*0.005) {
        vec2 pickCoord;
        float Y = mix(hex.y, 0.5, u_Pixelate*0.01);
        float a = hex.x;
        pickCoord = hex.zw + Y*vec2(0.0, 0.5);
        absCoord = (u_InverseModelTransform * vec3(pickCoord, 1.0)).xy;
        outCol = texture2D(u_Tex0, proj0(absCoord));
    }
    else {
        absCoord = (u_InverseModelTransform * vec3(hex.zw, 1.0)).xy;
        outCol = texture2D(u_Tex0, proj0(absCoord));
        outCol = mix(outCol, vec4(u_Color1.rgb, outCol.a), u_Color1.a);
    }

    if (u_Brightness!=0.0) {
        float b = 1.0 + u_Brightness*0.01;
        outCol *= vec4(b, b, b, 1.0);
    }
    if (u_Saturation!=1.0) {
        float grey = 0.2126*outCol.r + 0.7152*outCol.g + 0.0722*outCol.b;
        outCol.rgb = grey + (outCol.rgb-grey) * u_Saturation;
    }

    vec4 inCol = texture2D(u_Tex0, proj0(pos));
    return mix(inCol, outCol, getLocus(absCoord, inCol, outCol));

}

#include mainWithOutPos(hex)
