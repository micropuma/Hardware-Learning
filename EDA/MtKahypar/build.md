# 项目构建  
## 构建步骤
在有sudo权限的机子上构建，参考github的readme即可。  
针对没有sudo权限的服务器，需要在用户空间中构建和安装软件。  
### 创建本地安装目录和项目目录
1. 本地安装目录：  
    ```shell
    mkdir -p ~/local
    ```
2. 本地项目目录： 
    ```shell
    mkdir -p ~/app
    ```
### 安装boost
1. 去[boost官网](https://sourceforge.net/projects/boost/)，下载压缩安装包，放到app/boot下，并解压缩。  
2. 进入加压好的文件夹，运行boostrap构建。
    ```shell
    ./bootstrap.sh --prefix=/usr/local
    ./b2 install
    ```
3. 检查安装目录，并在~/.bashrc设定环境变量。
    ```shell
    export BOOST_ROOT=$HOME/local/boost
    export LD_LIBRARY_PATH=$BOOST_ROOT/lib:$LD_LIBRARY_PATH
    source ~/.bashrc
    ```
4. 由于我安装的是1.83.0版本的boost，所以要修改项目CMakeLists中的boost版本要求。

### 安装TBB
选择源码构建，[oneTBB](https://github.com/oneapi-src/oneTBB)中有详细build说明。  
```shell
# Do our experiments in /tmp
cd /tmp
# Clone oneTBB repository
git clone https://github.com/oneapi-src/oneTBB.git
cd oneTBB
# Create binary directory for out-of-source build
mkdir build && cd build
# Configure: customize CMAKE_INSTALL_PREFIX and disable TBB_TEST to avoid tests build
cmake -DCMAKE_INSTALL_PREFIX=/tmp/my_installed_onetbb -DTBB_TEST=OFF ..
# Build
cmake --build .
# Install
cmake --install .
# Well done! Your installed oneTBB is in /tmp/my_installed_onetbb
```
修改tmp文件，以及install的路径即可。添加环境变量同理boost的流程。  

### 安装hwloc
1. 去[hwloc download网页](https://www.open-mpi.org/software/hwloc/v2.11/)下载压缩包，放在/app下并解压。  
2. 用config可执行部署即可，和boost的安装一致。  

## References
1. [MtKaHypar github主页](https://github.com/micropuma/mt-kahypar-leon/tree/master)