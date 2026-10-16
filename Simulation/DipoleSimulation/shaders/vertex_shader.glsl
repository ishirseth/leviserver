#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in float ar;

uniform mat4 projection;
uniform mat4 view;

out float vr;

void main() {
    gl_Position = projection * view * vec4(aPos, 1.0);

    float baseSize = 20.0;

    gl_PointSize = baseSize / gl_Position.w;

    vr = ar;
}