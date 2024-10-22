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
2. [安装Vitis](../../../EDA/Vitis/build.md)    
    注意，构建好Vitis项目后（比如在），运行`/usr/xilinx/Environment_Bash/AIE.sh`脚本，**会导致PATH环境中添加cmake 3.3.2版本，与本项目的3.20+要求冲突**。。因此选择手动添加所需要的Vitis安装路径到PATH中即可。
3.  利用脚本安装prerequisite  
    ```shell
    source /utils/setup_python_packages.sh
    ```  
    > 官网说需要virtualenv，但是脚本中实际使用的是python venv, 需要自行针对修改。
4. clone项目   
    ```shell
    git clone --recurse-submodules https://github.com/Xilinx/mlir-aie.git
    cd mlir-aie
    ```     
    后续操作就都在/mlir-aie路径下操作。 
5. clone llvm
    ```shell  
    ./utils/clone-llvm.sh
    ```
6. build llvm  
    ```shell  
    ./utils/build-llvm-local.sh
    ``` 
    上述命令是构建在llvm项目下的/install中，如果有root权限，可以make install到系统环境中。该脚本配置的是19.0.0版本llvm。
7. build mlir-aie（非VCK5000系统，没有Rocm）  
    ```shell    
    source <Vitis Install Path>/settings64.sh
    ./utils/build-mlir-aie.sh <llvm dir>/<build dir>
    ```   
8. 添加mlir-aie以及llvm环境到环境变量  
    ```shell
    source utils/env_setup.sh <mlir-aie>/install <llvm dir>/install
    ```  
    运行上述脚本，如果没有构建llvm-aie项目，脚本会http在线下载llvm-aie，比较慢。选择自行手动下载whl文件或是源码编译，并提供llvm-aie的install路径即可。  
    > <font color = red>注意，由于使用virtualenv虚拟环境，所以慎用相对路径。</font>  
9. 检查build是否成功:  
    可以通过`echo $PATH`看环境。`aie-opt --version`等check
