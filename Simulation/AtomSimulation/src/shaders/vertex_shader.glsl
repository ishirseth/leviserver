#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in float aType;
layout (location = 2) in float ar;

uniform mat4 projection;
uniform mat4 view;

out float vType;
out float vr;

void main() {
    gl_Position = projection * view * vec4(aPos, 1.0);

    float baseSize = (aType > 0.5) ? 70.0 : 5.0;

    // Perspective scaling
    gl_PointSize = baseSize * 100.0 / gl_Position.w;
    gl_PointSize = clamp(gl_PointSize, 1.0, 50.0);

    vType = aType;
    vr = ar;
}