precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun

uniform float u_Brightness;
uniform float u_Saturation;
uniform float u_Contrast;
uniform float u_HueShift;
uniform float u_Vignetting;
uniform float u_BlurVignetting;
uniform mat3 u_InverseModelTransform;


float hueToRGB(float p, float q, float h)
{
    if (h < 0.0) h += 1.0;

    if (h > 1.0 ) h -= 1.0;

    if (6.0 * h < 1.0)
    {
        return p + ((q - p) * 6.0 * h);
    }

    if (2.0 * h < 1.0 )
    {
        return  q;
    }

    if (3.0 * h < 2.0)
    {
        return p + ( (q - p) * 6.0 * ((2.0 / 3.0) - h) );
    }

    return p;
}

vec4 RGBtoHSL(vec4 color) {
    //	Minimum and Maximum RGB values are used in the HSL calculations
    float mini = min(color.r, min(color.g, color.b));
    float maxi = max(color.r, max(color.g, color.b));

    //  Calculate the Hue
    float h = 0.0;

    if (maxi == mini)
        h = 0.0;
    else if (maxi == color.r)
        h = fmod(((60.0 * (color.g - color.b) / (maxi - mini)) + 360.0), 360.0);
    else if (maxi == color.g)
        h = (60.0 * (color.b - color.r) / (maxi - mini)) + 120.0;
    else if (maxi == color.b)
        h = (60.0 * (color.r - color.g) / (maxi - mini)) + 240.0;

    //  Calculate the Luminiance
    float l = (maxi + mini) / 2.0;

    //  Calculate the Saturation
    float s = 0.0;

    if (maxi == mini)
        s = 0.0;
    else if (l <= 0.5)
        s = (maxi - mini) / (maxi + mini);
    else
        s = (maxi - mini) / (2.0 - maxi - mini);

    return vec4(h, s, l, color.a);
}

vec4 HSLtoRGB(vec4 color) {
    //  Formula needs all values between 0 - 1.
    float h = fmod(color.r, 360.0);
    h /= 360.0;
    float s = color.g;
    float l = color.b;

    float q = 0.0;

    if (l < 0.5)
        q = l * (1.0 + s);
    else
        q = (l + s) - (s * l);

    float p = 2.0 * l - q;

    vec4 outColor = vec4(max(0.0, hueToRGB(p, q, h + (1.0 / 3.0))),
                    max(0.0, hueToRGB(p, q, h)),
                    max(0.0, hueToRGB(p, q, h - (1.0 / 3.0))),
                    color.a);
    outColor = min(outColor, 1.0);

    return outColor;
}

vec4 blur(vec2 pos, float radius) {
    float pixel = 2.0 / u_Tex0Dim.y;
    int n = int(ceil(radius / pixel))+1;
    vec4 total = vec4(0.0, 0.0, 0.0, 0.0);
    vec2 p = pos - float(n)*pixel;
    float div = 0.0;
    for(int j = -n; j<=n; ++j) {
        p.x = pos.x - float(n)*pixel;
        for(int i=-n; i<=n; ++i) {
            float d = length(vec2(float(i), float(j))) * pixel / radius;
            if (d<=1.0) {
//                float k = 1.0-d;
                float k = (d>0.5) ? (1.0-d)*(1.0-d)*2.0 : 1.0 - d*d*2.0;
                total += k*texture2D(u_Tex0, proj0(p));
                div += k;
                p.x += pixel;
            }
        }
        p.y += pixel;
    }
    return total / div;
}

vec4 blurH(vec2 pos, float radius) {
    float pixel = 2.0 / u_Tex0Dim.y;
    int n = int(ceil(radius / pixel))+1;
    vec4 total = vec4(0.0, 0.0, 0.0, 0.0);
    vec2 p = pos - vec2(float(n)*pixel, 0.0);
    float div = 0.0;
    for(int i=-n; i<=n; ++i) {
        float d = length(vec2(float(i), 0.0)) * pixel / radius;
        if (d<=1.0) {
//                float k = 1.0-d;
            float k = (d>0.5) ? (1.0-d)*(1.0-d)*2.0 : 1.0 - d*d*2.0;
            total += k*texture2D(u_Tex0, proj0(p));
            div += k;
            p.x += pixel;
        }
    }
    return total / div;
}

vec4 adjust(vec2 pos, vec2 outPos) {
    vec4 color = texture2D(u_Tex0, proj0(pos));

    if (u_BlurVignetting != 0.0) {
        vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;
        float ratio = min(1.0, length(u));
        float k = ratio*u_BlurVignetting;

        float radius = k*0.05;
        color = blurH(pos, radius);
    }

    if (u_Brightness!=0.0) {
        color.rgb += u_Brightness;
    }

    if (u_Vignetting != 0.0) {
        vec2 u = (u_InverseModelTransform * vec3(pos, 1.0)).xy;
        float ratio = min(1.0, length(u));
        float k = 1.0 - ratio*u_Vignetting;
        color.rgb *= k;
	}

	if (u_Contrast != 1.0) {
	    color.rgb = (color.rgb - 0.5)*u_Contrast + 0.5;
	}

    if (u_Saturation != 1.0) {
        float grey = 0.2126*color.r + 0.7152*color.g + 0.0722*color.b;
        color.rgb = grey + (color.rgb-grey) * u_Saturation;
    }

    if (u_HueShift != 0.0) {
        vec4 hsl = RGBtoHSL(clamp(color, 0.0, 1.0));
        hsl.r += u_HueShift;
        color = HSLtoRGB(hsl);
    }



    return color;
}

#include mainWithOutPos(adjust) // should disable antialias
