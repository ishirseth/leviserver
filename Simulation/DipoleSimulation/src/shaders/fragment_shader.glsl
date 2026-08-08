#version 330 core

in float vr;
out vec4 FragColor;

void main() {        
    float dist = distance(gl_PointCoord, vec2(0.5, 0.5));
    if (dist > 0.3) discard;

    if(vr < 0.01){
        FragColor = vec4(0.0, 1.0, 0.2, 1.0);
    }
    else{
        vec3 innerColor = vec3(0.0, 0.0, 1.0);
        vec3 outerColor = vec3(1.0, 0.0, 0.0);
        vec3 mixedColor = mix(innerColor, outerColor, vr*1.0);
        FragColor = vec4(mixedColor, 1.0);
    }
}