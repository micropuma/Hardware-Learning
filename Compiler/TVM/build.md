# Build from source 
tvm 的构建，采用如下策略：
* 部署使用docker快速高效部署。
* 源码debug+修改使用源码构建

本构建说明讲解如何源码构建。

## Clone code
构建符合依赖项目的conda环境：
```shell
conda create -n tvm-build-venv -c conda-forge \
    "llvmdev>=15" \
    "cmake>=3.24" \
    git \
    python=3.11

conda activate tvm-build-venv
```


在检查好依赖项后，clone并构建。
```shell
git clone --recursive https://github.com/apache/tvm tvm
```

### config & build
直接运行如下脚本即可：
```shell
rm -rf build && mkdir build && cd build
# Specify the build configuration via CMake options
cp ../cmake/config.cmake .

# controls default compilation flags (Candidates: Release, Debug, RelWithDebInfo)
echo "set(CMAKE_BUILD_TYPE RelWithDebInfo)" >> config.cmake

# LLVM is a must dependency for compiler end
echo "set(USE_LLVM \"llvm-config --ignore-libllvm --link-shared\")" >> config.cmake
echo "set(HIDE_PRIVATE_SYMBOLS ON)" >> config.cmake

# GPU SDKs, turn on if needed
echo "set(USE_CUDA   ON)" >> config.cmake
echo "set(USE_METAL  OFF)" >> config.cmake
echo "set(USE_VULKAN OFF)" >> config.cmake
echo "set(USE_OPENCL OFF)" >> config.cmake

# cuBLAS, cuDNN, cutlass support, turn on if needed
echo "set(USE_CUBLAS OFF)" >> config.cmake
echo "set(USE_CUDNN  OFF)" >> config.cmake
echo "set(USE_CUTLASS OFF)" >> config.cmake

cmake .. -DGTest_DIR=/home/douliyang/local/GTEST/lib/cmake/GTest && cmake --build . --parallel $(nproc)
```
改脚本是总结官方文档的配置，编写的一键构建脚本。需要自行修改一下构建细节。我针对我的环境做了如下修改：  
* set选项选择CUDA为on，其他device为off。
* llvm项目的链接，我选择链接为`-link-shared`，因为我的已有llvm项目的lib都是动态库。
* `DGTest_DIR`选择传入源码编译的google test路径。

上述构建过程成功与否通过是否有如下两个文件判断：
1. build/libtvm.so
2. build/libtvm_runtime.so

## Install tvm
只用运行如下脚本即可：
```shell
# set up tvm environment

export TVM_HOME=/home/douliyang/large/tvm-workspace/tvm-dly
export PYTHONPATH=$TVM_HOME/python:$PYTHONPATH
```

## Test tvm setup
运行官网给的测试脚本，只要输出正确即可。
```shell
>>> python -c "import tvm; print(tvm.__file__)"
/some-path/lib/python3.11/site-packages/tvm/__init__.py
```

```shell
>>> python -c "import tvm; print(tvm._ffi.base._LIB)"
<CDLL '/some-path/lib/python3.11/site-packages/tvm/libtvm.dylib', handle 95ada510 at 0x1030e4e50>
```

```shell
>>> python -c "import tvm; print('\n'.join(f'{k}: {v}' for k, v in tvm.support.libinfo().items()))"
... # Omitted less relevant options
GIT_COMMIT_HASH: 4f6289590252a1cf45a4dc37bce55a25043b8338
HIDE_PRIVATE_SYMBOLS: ON
USE_LLVM: llvm-config --link-static
LLVM_VERSION: 15.0.7
USE_VULKAN: OFF
USE_CUDA: OFF
CUDA_VERSION: NOT-FOUND
USE_OPENCL: OFF
USE_METAL: ON
USE_ROCM: OFF
```

```shell
>>> python -c "import tvm; print(tvm.metal().exist)"
True # or False
>>> python -c "import tvm; print(tvm.cuda().exist)"
False # or True
>>> python -c "import tvm; print(tvm.vulkan().exist)"
False # or True
```

## Extra python env
上述源码编译会欠缺部分python环境，按照如下脚本运行即可：
```shell
pip3 install numpy decorator attrs
pip3 install tornado
pip3 install tornado psutil 'xgboost>=1.1.0' cloudpickle
```

## References 
1. [TVM from source doc](https://tvm.apache.org/docs/install/from_source.html)