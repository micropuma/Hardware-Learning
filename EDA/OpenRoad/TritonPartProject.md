# TritonPart项目  
## 项目构建
阅读TirtonPart的github readme.md，明确构建项目步骤：
1. clone项目
    ```shell
    git clone https://github.com/ABKGroup/TritonPart.git
    ```
2. TritonPart是OpenROAD的子项目，需要构建OpenROAD的依赖环境。
    ```shell
    sudo ./etc/DependencyInstaller.sh
    ```
3. 安装OR线性求解器
    ```shell
    python -m pip install ortools
    ```
3. 构建TritonPart项目
    ```shell
    mkdir build
    cd build
    cmake ../OpenROAD/
    make
    ```

## 源码分析


## References
1. [TritonPart github项目](https://github.com/ABKGroup/TritonPart)
2. [OpenROAD github项目](https://github.com/The-OpenROAD-Project/OpenROAD/tree/master)
3. [OpenROAD 官网](https://openroad.readthedocs.io/en/latest/)
3. [OpenROAD build](https://openroad.readthedocs.io/en/latest/user/Build.html)