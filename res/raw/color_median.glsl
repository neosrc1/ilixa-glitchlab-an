precision highp float;
precision highp int;

#include math
#include commonvar
#include commonfun
#include random

uniform float u_Radius;
uniform float u_Dampening;
vec4 colors[121];


float lum(vec4 color) {
    return color.r + color.g + color.b;
}

vec4 selectKth(int len, int k){
//vec4 selectKth(vec4 colors[121], int len, int k){
    int left = 0;
    int right = len-1;

    //we stop when our indicies have crossed
    while (left < right){

        int pivot = (left + right)/2; //this can be whatever
        vec4 pivotValue = colors[pivot];
        int storage=left;

        colors[pivot] = colors[right];
        colors[right]=pivotValue;
        for(int i =left; i < right; i++){//for each number, if its less than the pivot, move it to the left, otherwise leave it on the right
            float lumPivotValue = lum(pivotValue);
            if (lum(colors[i]) < lumPivotValue) {
                vec4 temp = colors[storage];
                colors[storage] = colors[i];
                colors[i]=temp;
                storage++;
            }
        }
        colors[right]=colors[storage];
        colors[storage]=pivotValue;//move the pivot to its correct absolute location in the list

        //pick the correct half of the list you need to parse through to find your K, and ignore the other half
        if(storage < k)
            left = storage+1;
        else//storage>= k
            right = storage;
    }
    return colors[k];
//    return colors[0];
}


vec4 median(vec2 pos) {
    float pixel = 2.0 / u_Tex0Dim.y;
    float radius = u_Radius * 0.01 * 0.05; // max radius is 1/40th of image size
    int n = int(ceil(radius / pixel))+1;
    if (n>5) n = 5;
//    vec4 colors[121];

    vec2 p = pos - vec2(0.0, float(n)*pixel);
    float div = 0.0;
    int index = 0;
    for(int j = -n; j<=n; ++j) {
        for(int i = -n; i<=n; ++i) {
//            sum += texture2D(u_Tex0, proj0(pos + vec2(float(i), float(j))*pixel));
            colors[index++] = texture2D(u_Tex0, proj0(p));
            p.x += pixel;
        }

        p.x = pos.x - float(n)*pixel;
        p.y += pixel;
    }

//    return selectKth(colors, index, index/2);
    return selectKth(index, index/2);
}

vec4 median2(vec2 pos) {
    float pixel = 2.0 / u_Tex0Dim.y;
    float radius = u_Radius * 0.01 * 0.05; // max radius is 1/40th of image size
    int n = 121;
    int m = 30;

    vec4 c = texture2D(u_Tex0, proj0(pos));

    float div = 0.0;
    int index = 0;
    for(int i = 0; i<n; ++i)  {
        vec2 prnd = pos + 2.0*radius * rand2rel(pos+vec2(float(i), 0.0));
        vec4 col = texture2D(u_Tex0, proj0(prnd));
        if (length(col-c)<=u_Dampening*0.01) {
            colors[index++] = col;
        }
        if (index>=m) break;
    }

//    return selectKth(colors, index, index/2);
    return selectKth(index, index/2);
}

vec4 median3(vec2 pos) {
    float pixel = 2.0 / u_Tex0Dim.y;
    float radius = u_Radius * 0.01 * 0.05; // max radius is 1/40th of image size
    int n = 50;
    int m = 5;

    vec4 c = texture2D(u_Tex0, proj0(pos));

    float div = 0.0;
    int index = 0;
    vec2 delta = rand2rel(pos);
    for(int i = 0; i<n; ++i)  {
        vec2 prnd = pos + 2.0*radius * delta;
        vec4 col = texture2D(u_Tex0, proj0(prnd));
        if (length(col-c)<=u_Dampening*0.01) {
            colors[index++] = col;
        }
        if (fmod(float(i), 4.0)==3.0) {
            delta = vec2(delta.y, -delta.x);
        }
        else {
            delta = rand2rel(delta);
        }
        if (index>=m) break;
    }

//    return selectKth(colors, index, index/2);
    return selectKth(index, index/2);
}

#include mainPerPixel(median2)
