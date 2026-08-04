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


// \dfrac{-\hbar^2}{2m}\nabla^2\Psi(\vec{r}) +V(\vec{r})\Psi(\vec{r}) = E\Psi(\vec{r}) \label{genSchr}
// Radial: Rₙₗ(r) = -√[ (2/na₀)³ · (n-l-1)! / (2n·[(n+l)!]³) ] · e^(-r/na₀) · (2r/na₀)^l · L^(2l+1)_(n-l-1)(2r/na₀)
// Prob: P(r) = 4πr² · [Rₙₗ(r)]²
// Angular: Yₗ⁰(θ) = √[ (2l+1)/(4π) ] · Pₗ⁰(cos θ)
// Prob: P(θ) = |Yₗ⁰(θ)|² · sin(θ) = [Pₗ⁰(cosθ)]² · (constant) · sin(θ)

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

float randfThreadLocal(std::mt19937& localRng, std::uniform_real_distribution<float>& localDist) {
    return localDist(localRng);
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

float laguerre(int n, int k, float x) {     // gives laguerre curve
    if (n == 0) return 1.0f;
    if (n == 1) return -x + k + 1.0f;
    float Lprev2 = 1.0f, Lprev1 = -x + k + 1.0f, Lcurrent = 0.0f;
    for (int i = 2; i <= n; i++) {
        Lcurrent = ((2.0f*i + k - 1.0f - x) * Lprev1 - (i + k - 1.0f) * Lprev2) / i;
        Lprev2 = Lprev1; Lprev1 = Lcurrent;
    }
    return Lcurrent;
}
// Associated Legendre polynomial
float legendre(int l, int m, float x) {
    float pmm = 1.0f;
    if (m > 0) {
        float somx2 = sqrt((1.0f - x) * (1.0f + x));
        float fact = 1.0f;
        for (int i = 1; i <= m; i++) {
            pmm *= -fact * somx2;
            fact += 2.0f;
        }
    }
    if (l == m) return pmm;

    float pmmp1 = x * (2.0f * m + 1.0f) * pmm;
    if (l == m + 1) return pmmp1;

    float pll = 0.0f;
    for (int ll = m + 2; ll <= l; ll++) {
        pll = ((2.0f * ll - 1.0f) * x * pmmp1 - (ll + m - 1.0f) * pmm) / (ll - m);
        pmm = pmmp1;
        pmmp1 = pll;
    }
    return pll;
}

double factorial(double x) {
    double result = 1.0;
    for (int i = 2; i <= x; i++) result *= i;
    return result;
}

float radialProbabilityGeneral(int n, int l, float r, float a0) {
    const float pi = 3.14159265358979f;
    float rho = (2.0f * r) / (n * a0);
    double normalization = sqrt(pow(2.0f / (n * a0), 3.0) * factorial(n - l - 1) / (2.0f * n * pow(factorial(n + l), 3.0)));
    float R = (float)normalization * exp(-rho / 2.0f) * pow(rho, (float)l) * laguerre(n - l - 1, 2*l + 1, rho);
    return 4.0f * pi * r * r * R * R;
}
// Angular probability
float angularProbabilityGeneral(int l, int m, float theta, float phi) {
    float x = cos(theta);
    float P = legendre(l, abs(m), x); 

    float phiPart = 1.0f; // default for m=0, no phi dependence
    if (m > 0) {
        phiPart = cos(m * phi);
    } else if (m < 0) {
        phiPart = sin(abs(m) * phi);
    }

    return P * P * phiPart * phiPart * sin(theta);
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

void generateChunk(int startI, int endI, int orbitals, int amqn, int mqn, float a0, float maxRadius, float sliceFactor, float maxProb, float nucleusOffset, std::vector<float>& outVertices) {
    std::mt19937 localRng(std::random_device{}());
    std::uniform_real_distribution<float> localDist(0.0f, 1.0f);

    for (int i = startI; i < endI; i++) {
        float r, polarAngle, azimuthAngle, prob, randVal;
        do {
            r = nucleusOffset + randfThreadLocal(localRng, localDist) * (maxRadius - nucleusOffset);
            polarAngle = randfThreadLocal(localRng, localDist) * 3.14159265f;
            azimuthAngle = randfThreadLocal(localRng, localDist) * 6.28318530f;

            float radialProb = radialProbabilityGeneral(orbitals, amqn, r, a0);
            float angularProb = angularProbabilityGeneral(amqn, mqn, polarAngle, azimuthAngle);

            prob = (radialProb * angularProb) / maxProb;
            randVal = randfThreadLocal(localRng, localDist);
        } while (randVal >= prob);

        glm::vec3 pos = polarCartesian(polarAngle, azimuthAngle * sliceFactor, r);
        outVertices.push_back(pos.x);
        outVertices.push_back(pos.y);
        outVertices.push_back(pos.z);
        outVertices.push_back(0);
        outVertices.push_back(r);
    }
}

std::vector<float> calculateOrbitalCutoffs(int maxOrbitals, float a0, float searchRange, float threshold = 0.8f) {
    std::vector<float> cutoffs;

    for (int n = 1; n <= maxOrbitals; n++) {
        int l = 0; 

        float totalProb = 0.0f;
        for (float r = 0.0f; r <= searchRange; r += 0.001f) {
            totalProb += radialProbabilityGeneral(n, l, r, a0) * 0.001f;
        }

        float runningTotal = 0.0f;
        float cutoffRadius = searchRange; 
        for (float r = 0.0f; r <= searchRange; r += 0.001f) {
            runningTotal += radialProbabilityGeneral(n, l, r, a0) * 0.001f;
            if (runningTotal >= threshold * totalProb) {
                cutoffRadius = r;
                break;
            }
        }

        cutoffs.push_back(cutoffRadius);
    }

    return cutoffs;
}

std::vector<float> calculateAtom(int orbitals, int amqn, int mqn, float a0, float maxRadius, float sliceFactor, int numPoints) {
    std::vector<float> vertices = {
        0.0f, 0.0f, 0.0f, 1, 0.0f   // nucleus
    };

    float maxAngularProb = 0.0f;
    for (float theta = 0.0f; theta <= 3.14159265f; theta += 0.01f) {
        for (float phi = 0.0f; phi <= 6.28318530f; phi += 0.01f) {
            float val = angularProbabilityGeneral(amqn, mqn, theta, phi);
            if (val > maxAngularProb) maxAngularProb = val;
        }
    }

    float maxRadialProb = 0.0f;
    for (float rTest = 0.0f; rTest <= maxRadius; rTest += 0.001f) {
        float val = radialProbabilityGeneral(orbitals, amqn, rTest, a0);
        if (val > maxRadialProb) maxRadialProb = val;
    }

    float maxProb = maxRadialProb * maxAngularProb;
    float nucleusOffset = 0.05f;

    unsigned int numThreads = std::thread::hardware_concurrency(); 
    if (numThreads == 0) numThreads = 4; 

    std::vector<std::thread> threads;
    std::vector<std::vector<float>> threadResults(numThreads); // one output vector per thread

    int pointsPerThread = numPoints / numThreads;

    for (unsigned int t = 0; t < numThreads; t++) {
        int startI = t * pointsPerThread;
        int endI = (t == numThreads - 1) ? numPoints : startI + pointsPerThread; 
        threads.emplace_back(generateChunk, startI, endI, orbitals, amqn, mqn, a0, maxRadius, sliceFactor, maxProb, nucleusOffset, std::ref(threadResults[t]));
    }

    for (auto& th : threads) {
        th.join(); 
    }

    for (auto& chunk : threadResults) {
        vertices.insert(vertices.end(), chunk.begin(), chunk.end());
    }

    return vertices;
}


int main() {
    // make the widndow
    if (!glfwInit()) return -1;
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    GLFWwindow* window = glfwCreateWindow(1024, 768, "Atom", nullptr, nullptr);
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

    // calculate the atom
    int maxOrbitals = 11;
    int orbitals = 5;   // amount of orbitals the atom has - n
    int amqn = 1;   // angular momentum quantum number - l
    int mqn = 0;      // magnetic quantum number - m
    const float a0 = 0.3f; 
    const float baseRadius = 1.5f;
    float maxRadius = baseRadius * orbitals * orbitals;
    float sliceFactor = 1.0f;     // e.g. see a quarter half etc
    int numPoints = 1000000;
    std::vector<float> vertices = calculateAtom(orbitals, amqn, mqn, a0, maxRadius, sliceFactor, numPoints);
    int vertexCount = vertices.size() / 5;
    glBindBuffer(GL_ARRAY_BUFFER, VBO);     // bind the buffer and update
    glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(float), vertices.data(), GL_STATIC_DRAW);    // upload cpu verticies to the gpu
    std::vector<float> orbitalCutoffs = calculateOrbitalCutoffs(maxOrbitals, a0, 500.0f); // 11 orbitals, search up to r=500


    // Attributes
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);   // pos
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 1, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));     // type
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(2, 1, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(4 * sizeof(float)));     // radius (relative to nucleus)
    glEnableVertexAttribArray(2);

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
    unsigned int orbitalCutoffsLoc = glGetUniformLocation(prog, "orbitalCutoffs");
    glUniformMatrix4fv(projLoc, 1, GL_FALSE, glm::value_ptr(projection));
    glUniformMatrix4fv(viewLoc, 1, GL_FALSE, glm::value_ptr(view));
    glUniform1fv(orbitalCutoffsLoc, orbitalCutoffs.size(), orbitalCutoffs.data());

    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        //  gui
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        ImGui::SetNextWindowSize(ImVec2(350, 200));
        ImGui::Begin("Parameters");
        ImGui::SliderInt("Orbitals (n)", &orbitals, 1, maxOrbitals);     // max orbitals
        ImGui::SliderInt("Amqn (l)", &amqn, 0, orbitals - 1);
        ImGui::SliderInt("Mqn (m)", &mqn, -amqn, amqn);
        ImGui::Separator();
        ImGui::SliderFloat("Slice", &sliceFactor, 0.25f, 1.0f);
        ImGui::SliderInt("Particles", &numPoints, 50000, 5000000);
        if (amqn >= orbitals) {amqn = orbitals - 1;}    // check that l < n
        if (mqn > amqn) {mqn = amqn;}   // constrain mqn between amqn and -amqn
        if (mqn < -amqn) {mqn = -amqn;}
        if (ImGui::Button("Render"))
        {
            maxRadius = baseRadius * orbitals * orbitals;
            vertices = calculateAtom(orbitals, amqn, mqn, a0, maxRadius, sliceFactor, numPoints);
            vertexCount = vertices.size() / 5;
            glBindBuffer(GL_ARRAY_BUFFER, VBO);     // bind the buffer and update
            glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(float), vertices.data(), GL_STATIC_DRAW);    // upload cpu verticies to the gpu 
        }
        bool enterIsPressed = (glfwGetKey(window, GLFW_KEY_ENTER) == GLFW_PRESS);
        if (enterIsPressed && !enterWasPressed) {
            maxRadius = baseRadius * orbitals * orbitals;
            vertices = calculateAtom(orbitals, amqn, mqn, a0, maxRadius, sliceFactor, numPoints);
            vertexCount = vertices.size() / 5;
            glBindBuffer(GL_ARRAY_BUFFER, VBO);
            glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(float), vertices.data(), GL_STATIC_DRAW);
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
        
        // render atom and gui
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
