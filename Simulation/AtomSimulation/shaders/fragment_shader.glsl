#version 330 core
in float vType;
in float vr;
out vec4 FragColor;

int maxOrbitals = 11;
uniform float orbitalCutoffs[11];

vec3 colorByOrbital(float vr) {
    vec3 colors[11];
    colors[0] = vec3(0.75, 0.90, 1.00);  // pale sky blue
    colors[1] = vec3(0.40, 0.80, 0.95);  // cyan-blue
    colors[2] = vec3(0.30, 0.85, 0.65);  // teal green
    colors[3] = vec3(0.55, 0.85, 0.35);  // fresh green
    colors[4] = vec3(0.85, 0.80, 0.30);  // warm gold
    colors[5] = vec3(0.90, 0.60, 0.25);  // amber orange
    colors[6] = vec3(0.85, 0.40, 0.25);  // burnt orange / rust
    colors[7] = vec3(0.75, 0.30, 0.35);  // deep red
    colors[8] = vec3(0.55, 0.35, 0.65);  // muted violet
    colors[9] = vec3(0.35, 0.40, 0.75);  // indigo
    colors[10] = vec3(0.60, 0.60, 0.65); // cool gray

    int orbitalIndex = 0;
    for (int i = 0; i < maxOrbitals; i++) {
        if (vr >= orbitalCutoffs[i]) {
            orbitalIndex = i;
        }
    }

    return colors[orbitalIndex % 11];
}

void main() {        
    float dist = distance(gl_PointCoord, vec2(0.5, 0.5));
    if (dist > 0.3) discard;

    if (vType == 1){
        FragColor = vec4(1.0, 0.3, 0.1, 1.0);
    }
    else if (vType == 0){
        vec3 color = colorByOrbital(vr);
        FragColor = vec4(color, 1.0);
    }
}