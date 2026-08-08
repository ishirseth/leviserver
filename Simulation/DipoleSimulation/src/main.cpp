#include <GLAD/gl.h>
#include <GLFW/glfw3.h>
#include <fstream>
#include <sstream>
#include <cmath>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <iostream>
#include <random>
#include "imgui.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"
#include <thread>

// G(theta) = ( (cos((2*pi*L/lambda) * cos(theta)) - cos(2*pi*L/lambda)) / sin(theta) )^2
// L = have length of the dipole

std::string load(const std::string& p) {
    std::ifstream f(p);
    std::stringstream ss;
    ss << f.rdbuf();
    return ss.str();
}

unsigned int compile(unsigned int type, const std::string& src) {
    unsigned int id = glCreateShader(type);
    const char* ptr = src.c_str();
    glShaderSource(id, 1, &ptr, nullptr);
    glCompileShader(id);
    return id;
}


// zooming
double radius = 5.0f;       // dsitance from atom / zoom
void scrollCallback(GLFWwindow* window, double xoffset, double yoffset) {
    const float sensitivityZoom = 3.0f;
    const double maxZoom = sensitivityZoom;
    if (radius > maxZoom || yoffset < 0){
        radius = radius - yoffset * sensitivityZoom;
    }
}

glm::vec3 polarCartesian(float polarAngle, float azimuthAngle, float r){
    float x = r * sin(polarAngle) * cos(azimuthAngle);
    float y = r * sin(polarAngle) * sin(azimuthAngle);
    float z = r * cos(polarAngle);
    glm::vec3 pos(x, y, z);
    return pos;
}

std::mt19937 rng(std::random_device{}());
std::uniform_real_distribution<float> dist(0.0f, 1.0f);

float randf() {
    return dist(rng);
}

std::vector<float> drawLine(float sx, float sy, float sz, float ex, float ey, float ez){
    int resolution = 10000;
    glm::vec3 step((ex-sx) / resolution,  (ey-sy) / resolution,  (ez-sz) / resolution);
    glm::vec3 pos(sx, sy, sz);

    std::vector<float> outVertices = {};
    for (float i=0; i <= resolution; i++){
        outVertices.push_back(pos.x);
        outVertices.push_back(pos.y);
        outVertices.push_back(pos.z);
        pos = pos + step;
        outVertices.push_back(-1.0f);
    }
    return outVertices;
}

std::vector<float> calculateDipole(float lambda, float L, float dipoleRes, float sliceFactor){
    const float pi = 3.14159265358979f;
    const float phiStep = 10.0f / 200.0f / dipoleRes;
    const float thetaStep = 10.0f / 10000.0f / dipoleRes;

    struct Sample { float theta, phi, gain; };
    std::vector<Sample> samples;

    float maxGain = 0.0f;
    for (float theta = 0.0f; theta <= pi; theta += thetaStep) {
        for (float phi = 0.0f; phi <= pi*(sliceFactor*2); phi += phiStep) {
            float gain = ( pow(cos((2*pi/lambda) * L * cos(theta)) - cos((2*pi/lambda) * L), 2) 
                         / pow(sin(theta), 2) );
            samples.push_back({theta, phi, gain});
            if (gain > maxGain) maxGain = gain;
        }
    }

    std::vector<float> outVertices;
    outVertices.reserve(samples.size() * 4);
    for (const auto& s : samples) {
        float normGain = (maxGain > 0.0f) ? (s.gain / maxGain) : 0.0f;
        glm::vec3 pos = polarCartesian(s.theta, s.phi, normGain);
        outVertices.push_back(pos.x);
        outVertices.push_back(pos.y);
        outVertices.push_back(pos.z);
        outVertices.push_back(normGain);
    }
    return outVertices;
}

int main() {
    // make the widndow
    if (!glfwInit()) return -1;
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    GLFWwindow* window = glfwCreateWindow(1024, 768, "Dipole", nullptr, nullptr);
    if (!window) return glfwTerminate(), -1;
    glfwMakeContextCurrent(window);

    if (!gladLoadGL((GLADloadfunc)glfwGetProcAddress)) return -1;
    glEnable(GL_PROGRAM_POINT_SIZE);
    glEnable(GL_DEPTH_TEST); 

    // gui init
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");


    // OpenGL graphics init
    unsigned int VAO, VBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glBindVertexArray(VAO);

    glm::vec3 camPos(0.0f, 0.0f, 0.0f);
    double mouseX = 0, mouseY = 0;
    double lastMouseX = 0.0, lastMouseY = 0.0;
    float angleX = glm::radians(90.0f), angleY = 0.0f;
    float maxangleY = 1.5f; 
    bool wasDragging = false;
    bool enterWasPressed = false; 
    int state = 0;
    
    glm::vec3 startPos;
    glm::vec3 endPos;
    std::vector<float> vertices = {};
    std::vector<float> line = {};
    std::vector<float> point = {};

    float lamda = 1.0f;
    float L = 0.5f;
    float dipoleRes = 3.0f;
    float sliceFactor = 1.0f;

    point = calculateDipole(lamda, L, dipoleRes, sliceFactor);
    vertices.insert(vertices.end(), point.begin(), point.end());

    startPos = glm::vec3(0.0f,  0.0f,  -10.0f);
    endPos = glm::vec3(0.0f,  0.0f,  10.0f);
    line = drawLine(startPos.x, startPos.y, startPos.z, endPos.x, endPos.y, endPos.z);
    vertices.insert(vertices.end(), line.begin(), line.end());

    
    int vertexCount = vertices.size() / 4;
    glBindBuffer(GL_ARRAY_BUFFER, VBO);     // bind the buffer and update
    glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(float), vertices.data(), GL_STATIC_DRAW);    // upload cpu verticies to the gpu


    // Attributes
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)0);   // pos
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 1, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)(3 * sizeof(float)));     // type
    glEnableVertexAttribArray(1);

    // assign glsl programs
    unsigned int prog = glCreateProgram();
    unsigned int vs = compile(GL_VERTEX_SHADER, load("shaders/vertex_shader.glsl"));
    unsigned int fs = compile(GL_FRAGMENT_SHADER, load("shaders/fragment_shader.glsl"));
    glAttachShader(prog, vs); glAttachShader(prog, fs);
    glLinkProgram(prog);
    glDeleteShader(vs); glDeleteShader(fs);

    // how 3D space maps onto 2D screen
    glm::mat4 projection = glm::perspective(
        glm::radians(45.0f),    //fov
        1024.0f / 768.0f,   // window size
        0.1f,   // near clipping
        1000.0f  // far clipping
    );
    // where the camera is and what it looks at
    glm::mat4 view = glm::lookAt(
        camPos,
        glm::vec3(0.0f, 0.0f, 0.0f),    // what it looks at
        glm::vec3(0.0f, 1.0f, 0.0f)     // direction of up
    );

    glUseProgram(prog);
    unsigned int projLoc = glGetUniformLocation(prog, "projection");
    unsigned int viewLoc = glGetUniformLocation(prog, "view");
    glUniformMatrix4fv(projLoc, 1, GL_FALSE, glm::value_ptr(projection));
    glUniformMatrix4fv(viewLoc, 1, GL_FALSE, glm::value_ptr(view));

    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        //  gui
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        ImGui::SetNextWindowSize(ImVec2(350, 200));
        ImGui::Begin("Parameters");
        ImGui::SliderFloat("lamda", &lamda, 0.1, 10.0);     // max orbitals
        ImGui::SliderFloat("L", &L, 0.1, 10.0);
        ImGui::Separator();
        ImGui::SliderFloat("Slice", &sliceFactor, 0.25f, 1.0f);
        ImGui::SliderFloat("Resolution", &dipoleRes, 1, 10);
        if (ImGui::Button("Render"))
        {
            vertices.clear();
            point = calculateDipole(lamda, L, dipoleRes, sliceFactor);
            vertices.insert(vertices.end(), point.begin(), point.end());
            startPos = glm::vec3(0.0f,  0.0f,  -10.0f);
            endPos = glm::vec3(0.0f,  0.0f,  10.0f);
            line = drawLine(startPos.x, startPos.y, startPos.z, endPos.x, endPos.y, endPos.z);
            vertices.insert(vertices.end(), line.begin(), line.end());        
            vertexCount = vertices.size() / 4;
            glBindBuffer(GL_ARRAY_BUFFER, VBO);     // bind the buffer and update
            glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(float), vertices.data(), GL_STATIC_DRAW);    // upload cpu verticies to the gpu
        }
        bool enterIsPressed = (glfwGetKey(window, GLFW_KEY_ENTER) == GLFW_PRESS);
        if (enterIsPressed && !enterWasPressed) {
            vertices.clear();
            point = calculateDipole(lamda, L, dipoleRes, sliceFactor);
            vertices.insert(vertices.end(), point.begin(), point.end());
            startPos = glm::vec3(0.0f,  0.0f,  -10.0f);
            endPos = glm::vec3(0.0f,  0.0f,  10.0f);
            line = drawLine(startPos.x, startPos.y, startPos.z, endPos.x, endPos.y, endPos.z);
            vertices.insert(vertices.end(), line.begin(), line.end());        
            vertexCount = vertices.size() / 4;
            glBindBuffer(GL_ARRAY_BUFFER, VBO);     // bind the buffer and update
            glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(float), vertices.data(), GL_STATIC_DRAW);    // upload cpu verticies to the gpu
        }
        enterWasPressed = enterIsPressed;
        ImGui::End();

        
        glfwGetCursorPos(window, &mouseX, &mouseY);
        int state = glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_RIGHT);
        if (state == GLFW_PRESS) {
            if (wasDragging) {
                double deltaX = mouseX - lastMouseX;
                double deltaY = mouseY - lastMouseY;
                const float sensitivityCam = 0.005f;

                angleX -= (float)deltaX * sensitivityCam; // sensitivity
                if (angleY < maxangleY || deltaY < 0){  
                    if (angleY > -maxangleY || deltaY > 0){
                        angleY += (float)deltaY * 0.005f;
                    }
                }
            }
            lastMouseX = mouseX;
            lastMouseY = mouseY;
            wasDragging = true;
        } else {
            wasDragging = false;
        }
        // move the camera around
        glfwSetScrollCallback(window, scrollCallback);
        camPos.x = cos(angleY) * sin(angleX) * radius;
        camPos.y = sin(angleY) * radius;
        camPos.z = cos(angleY) * cos(angleX) * radius;
        glm::mat4 view = glm::lookAt(
            camPos,
            glm::vec3(0.0f, 0.0f, 0.0f),  
            glm::vec3(0.0f, 1.0f, 0.0f)
        );
        glUniformMatrix4fv(viewLoc, 1, GL_FALSE, glm::value_ptr(view));

        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); 
        
        // render dipole and gui
        glUseProgram(prog);
        glBindVertexArray(VAO);
        glDrawArrays(GL_POINTS, 0, vertexCount);
        ImGui::Render();
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(window);
    }
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    glfwTerminate();
}
