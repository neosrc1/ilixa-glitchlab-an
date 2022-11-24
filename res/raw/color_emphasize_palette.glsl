precision highp float;
precision highp int;

#include commonvar
#include commonfun
#include math
#include hsl
#include color
#include locuswithcolor

uniform float u_Intensity;
uniform float u_Saturation;
uniform float u_Tolerance;
uniform float u_Separation;
uniform sampler2D u_Palette;
uniform int u_ColorCount;

//vec4 emphasize(vec2 pos) {
//    vec4 inc = texture2D(u_Tex0, proj0(pos));
//    vec4 total= vec4(0.0, 0.0, 0.0, 1.0);
//    float totalWeight = 0.0;
//    float separation = 0.0 + u_Separation*0.1;
//    float intensity = getMaskedParameter(u_Intensity, pos)*0.01;
//
//    float minDist = 10000.0;
//
//    for(int i=0; i<u_ColorCount; ++i) {
//        float x = (0.5 + float(i))/float(u_ColorCount);
//        vec4 target = texture2D(u_Palette, vec2(x, 0.0));
//
//        vec4 contribColor;
//        float k = 0.0;
//        float dist = length((inc-target).rgb);
//        float tolerance = u_Tolerance*0.0174;
//        if (dist < minDist) minDist = dist;
//        if (dist < tolerance) {
//            contribColor = vec4(
//                colorize(inc, target, u_Saturation*0.01).rgb,
//                inc.a );
//            //k = pow(tolerance/max(dist, 0.001), u_Separation*0.05);
//            k = pow(tolerance/(dist + 0.01), u_Separation*0.05);
//        }
//
//        k = pow(k, separation+0.5);
//        total += k*contribColor;
//        totalWeight += k;
//    }
//
//    float sourceContribWeight = float(u_ColorCount) * pow(2.0, u_Separation*0.05);
//    float k0 = clamp((sourceContribWeight - totalWeight)/sourceContribWeight, 0.0, 1.0);
//    //vec4 rgb = vec4(k0==1.0 ? inc.rgb : mix(total.rgb / totalWeight, inc.rgb, k0), inc.a); // weird alpha issue if k0==1.0 not handled separately
//    vec4 rgb = k0==1.0 ? inc : mix(total / (totalWeight==0.0 ? 1.0 : totalWeight), inc, k0); // weird alpha issue if k0==1.0 not handled separately
//    //rgb.a = 1.0;
//    return mix(inc, rgb, intensity);
//}
vec4 emphasize(vec2 pos) {
    vec4 inc = texture2D(u_Tex0, proj0(pos));
    vec4 total= vec4(0.0, 0.0, 0.0, 1.0);
    float totalWeight = 0.0;
    float separation = 0.0 + u_Separation*0.1;
    float intensity = getMaskedParameter(u_Intensity, pos)*0.01;

    float k0 = 1.0;

    for(int i=0; i<u_ColorCount; ++i) {
        float x = (0.5 + float(i))/float(u_ColorCount);
        vec4 target = texture2D(u_Palette, vec2(x, 0.0));

        vec4 contribColor = vec4(0.0, 0.0, 0.0, 1.0);
        float k = 0.0;
        float dist = length((inc-target).rgb);
        float tolerance = u_Tolerance*0.025;//0.0174;
        if (dist < tolerance) {
            contribColor = vec4(
                colorize(inc, target, u_Saturation*0.01).rgb,
                inc.a );
            k = 1.0-dist/tolerance;
        }

        k0 = max(0.0, k0-k);
        k = pow(k, separation+0.5);
        total += k*contribColor;
        totalWeight += k;
    }

    vec4 rgb = k0==1.0 ? inc : mix(total / totalWeight, inc, k0); // weird alpha issue if k0==1.0 not handled separately
    return mix(inc, rgb, intensity*getLocus(pos, inc, rgb));
}

#include mainPerPixel(emphasize)
