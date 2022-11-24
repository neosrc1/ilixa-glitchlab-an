precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#define SLOPE 1.7320508075688772

uniform float u_Dampening;
uniform float u_Count;

bool inTriangle(vec2 pos, vec2 root, float side, bool up) {
    float halfSide = side*0.5;
    if (pos.x>root.x+halfSide || pos.x<root.x-halfSide || pos.y<root.y || pos.y>root.y+halfSide*SLOPE) {
        return false;
    }

    if (up) {
        if (pos.x<root.x) {
            return (pos.x-root.x+halfSide)*SLOPE > pos.y-root.y;
        }
        else {
            return (root.x+halfSide-pos.x)*SLOPE > pos.y-root.y;
        }
    }
    else {
        if (pos.x<root.x) {
            return (halfSide - (pos.x-root.x+halfSide))*SLOPE < pos.y-root.y;
        }
        else {
            return (halfSide - (root.x+halfSide-pos.x))*SLOPE < pos.y-root.y;
        }
    }
}

vec4 sierpinski(vec2 u) {
    float size = 1.0;
    float halfSide = size*0.5;
    vec2 root = vec2(0.0, -0.4330127018922193*size);
    float inside = 0.0;

    if (inTriangle(u, root, size, true)) {
        inside = 1.0;
        for(int i = 0; i < int(u_Count); ++i) {
            if (inTriangle(u, root, size*0.5, false)) {
                inside = 0.0;
                break;
            }
            float quarterSide = halfSide*0.5;
            vec2 dx = vec2(quarterSide, 0.0);
            if (inTriangle(u, root-dx, halfSide, true)) {
                root -= dx;
            }
            else if (inTriangle(u, root+dx, halfSide, true)) {
                root += dx;
            }
            else {
                root += vec2(0.0, quarterSide*SLOPE);
            }
            size = halfSide;
            halfSide = quarterSide;
        }

    }

    return vec4(0.0, 0.0, 0.0, inside);
}

#include shapeMain(sierpinski)