# MLIR-AIE项目构建  
## Build流程
1. 安装Prerequest
    ```shell
    lld
    cmake 3.20.6
    ninja 1.8.2
    Xilinx Vitis 2023.2
    python 3.8.x and pip
    virtualenv
    pip3 install psutil rich pybind11 numpy
    clang/llvm 14+ from source https://github.com/llvm/llvm-project 
    ```  
2. 安装Vitis  
3. clone项目   
    ```shell
    git clone --recurse-submodules https://github.com/Xilinx/mlir-aie.git
    cd mlir-aie
    ```  
4. 

## 构建脚本解读  
