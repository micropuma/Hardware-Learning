# Verilator tutorial
## Build from source 
安装verilator有两种方式，一种是包管理，一种是源码编译。由于一生一芯需要5.008版本的verilator来支持systemverilog，需源码编译（**apt-get的版本一般为4.x.y**）。  
1. git clone源代码，并checkout到指定版本。  
    ```shell
    git clone git@github.com:verilator/verilator.git
    git tag # 查看verilator有哪些版本
    git checkout v5.008 # checkout到指定版本
    ```
2. 安装prerequisite  
    ```shell
    sudo apt-get install git help2man perl python3 make autoconf g++ flex bison ccache
    sudo apt-get install libgoogle-perftools-dev numactl perl-doc
    sudo apt-get install libfl2  # Ubuntu only (ignore if gives error)
    sudo apt-get install libfl-dev  # Ubuntu only (ignore if gives error)
    sudo apt-get install zlibc zlib1g zlib1g-dev  # Ubuntu only (ignore if gives error)
    ```
3. unset环境变量  
    ```shell
    unset VERILATOR_ROOT
    ```
4. 源码编译  
    ```shell
    cd verilator
    autoconf # 创建 ./configure 脚本  
    ./configure --prefix=/usr # 阅读makefile会发现，安装的PREFIX路径默认是/usr/local/bin，如果想要直接安装在/usr/bin下，不能修改makefile，而是给配置脚本传参 
    make -j $(nproc)
    make install
    verilator --version
    ```

> 注意：verilator的build过程要10分钟左右，并且swapspace要开辟至少10个G的空间。详情查看[swapspace的配置](../../Build_Install.md#交换空间)
## References  
1. [verilator官网教学](https://www.veripool.org/verilator/)
2. [verilator github仓库](https://github.com/verilator/verilator)
3. [verilator 安装教程路径](https://verilator.org/guide/latest/install.html)
4. [verilator manual](https://veripool.org/guide/latest/)
5. [verilator 插件配置](https://soc.ustc.edu.cn/Digital-Pro/lab0/Verilator/)