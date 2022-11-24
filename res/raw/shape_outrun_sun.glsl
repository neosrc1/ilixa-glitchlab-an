precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include locuswithcolor_nodep

uniform float u_Thickness;
uniform vec4 u_Color1;
uniform vec4 u_Color2;


vec4 shape(vec2 pos, vec2 outPos) {
    vec2 u = (u_ModelTransform * vec3(pos, 1.0)).xy;
    vec4 bkgCol = texture2D(u_Tex0, proj0(pos));

    float l = length(u);
    vec4 color = bkgCol;
    if (l<1.0) {
        if (u.y>0.0) {
        	float i = 1.0+u.y*(u_Thickness*0.04);
            if (fract(i*i)>0.5) {
    	        color = mix(u_Color1, u_Color2, 0.5+u.y*0.5);
            }
        }
        else if (u.y<=0.0) {
            color = mix(u_Color1, u_Color2, 0.5+u.y*0.5);
        }
    }

    float locIntensity = getLocus(pos, bkgCol, color);
    return mix(bkgCol, color, locIntensity);
}

#include mainWithOutPos(shape)
