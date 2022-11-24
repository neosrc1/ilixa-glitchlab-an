precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include locuswithcolor
#include tex(1)

uniform float u_Count;
uniform float u_Thickness;
uniform vec4 u_Color1;
uniform vec4 u_Color2;



float sample(vec2 pos) {
    vec4 color = texture2D(u_Tex1, proj1(pos));
    return floor((color.r + color.g + color.b)*(u_Count-1.0)/3.0 + 0.5);
}

bool onContour(vec2 pos, vec2 p) {
    float l = sample(pos);
    return (l!=sample(pos+p.xy)) || (l!=sample(pos-p.xy)) || (l!=sample(pos+p.yx)) || (l!=sample(pos-p.yx));
}

vec4 contour(vec2 pos, vec2 outPos) {
    float pixel = 2.0 / u_Tex0Dim.y;
    vec2 p = vec2(pixel, 0.0);

    float sum = 0.0;
    float max = 0.0;
    float fRadius = u_Thickness*0.0001 / pixel;
    int radius = int(floor(0.5 + fRadius));
    for(int j=-radius; j<=radius; ++j) {
        for(int i=-radius; i<=radius; ++i) {
            vec2 delta = vec2(float(i), float(j));
            if (length(delta)<fRadius) {
                sum += onContour(pos + delta*vec2(pixel, pixel), p) ? 1.0 : 0.0;
                max += 1.0;
            }
        }
    }

    vec4 color;
//    color = onContour(pos, p) ? u_Color2 : u_Color1;
    color = sum > 0.0 ? u_Color2 : u_Color1;
    vec4 bkgCol = texture2D(u_Tex0, proj0(pos));

    vec4 outCol = vec4(mix(bkgCol.rgb, color.rgb, color.a), bkgCol.a);
    return mix(bkgCol, outCol, getLocus(pos, bkgCol, outCol));
}

#include mainWithOutPos(contour)
