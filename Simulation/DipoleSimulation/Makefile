# Detect Operating System
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
else
    DETECTED_OS := $(shell uname -s)
endif

CXX = g++
CXXFLAGS = -std=c++17 -Wall \
           -Ilibs/glad \
           -Ilibs/glm \
           -Ilibs/imgui/IMGUI \
           -Ilibs/imgui/IMGUI/backends \
           $(shell pkg-config --cflags glfw3)

LIBS = $(shell pkg-config --libs glfw3) -lGL -ldl -lpthread

SRC = src/main.cpp \
      libs/glad/gl.c \
      libs/imgui/IMGUI/imgui.cpp \
      libs/imgui/IMGUI/imgui_draw.cpp \
      libs/imgui/IMGUI/imgui_tables.cpp \
      libs/imgui/IMGUI/imgui_widgets.cpp \
      libs/imgui/IMGUI/backends/imgui_impl_glfw.cpp \
      libs/imgui/IMGUI/backends/imgui_impl_opengl3.cpp

TARGET = main.exe

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(SRC) $(CXXFLAGS) $(LIBS) -o $(TARGET)

run: all
	./$(TARGET)

clean:
	rm -f $(TARGET)