# Makefile for Verilator project

# 设置变量
VERILATOR = verilator
CXX = g++
CXXFLAGS = -Wall -O2
V_FILES = our.v
SIM_MAIN = sim_main.cpp
OUTPUT = obj_dir/Vour

# 默认目标
all: $(OUTPUT)

# 生成 Verilator 的 C++ 代码
$(OUTPUT): $(V_FILES) $(SIM_MAIN)
	$(VERILATOR) --cc --exe --build -j 0 $(CXXFLAGS) $(SIM_MAIN) $(V_FILES)

# 编译生成的 C++ 文件
.PHONY: compile
compile:
	$(MAKE) -C obj_dir -f V$(basename $(SIM_MAIN)).mk

# 清理生成的文件
clean:
	rm -rf obj_dir
	rm -f $(OUTPUT)

# 运行仿真
run: all
	./$(OUTPUT)


