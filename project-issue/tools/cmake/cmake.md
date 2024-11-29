# Cmake tips and issues
## Classic vs. new Cmake 
refer to [cmake guide](https://cliutils.gitlab.io/modern-cmake/chapters/intro/running.html)
```shell
~/package $ mkdir build
~/package $ cd build
~/package/build $ cmake ..
~/package/build $ make
```
the shell script above is classical ones.
```shell
~/package $ cmake -S . -B build
~/package $ cmake --build build
```
the shell above is new one.

## Use cmake extension 
> CMake extension is easy for debug, test and so on.

* use .vscode/settings.json and .vscode/launch.json to configure the whole process.
* use CMakePresets.json, which is a more advanced topic. Remain further learning.

### How to set settings.json and launch.json?
following is command line option:
```shell
#!/bin/bash

BUILD_DIR="build"

if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

mkdir "$BUILD_DIR"

pushd "$BUILD_DIR"

BUILD_SYSTEM=Ninja
BUILD_DIR=./build-`echo ${BUILD_SYSTEM}| tr '[:upper:]' '[:lower:]'`

LLVM_BUILD_DIR=../llvm/build/

export PATH=/home/douliyang/large/mlir-workspace/mlir-aie/llvm/install/bin:$PATH

cmake -G Ninja .. \
    -DLLVM_DIR=$PWD/../../mlir-aie/build/lib/cmake/llvm \
    -DMLIR_DIR=$PWD/../../mlir-aie/build/lib/cmake/mlir \
    -DAIE_DIR=$PWD/../../mlir-aie/build/lib/cmake/aie \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DCMAKE_BUILD_TYPE=DEBUG \
    -DLLVM_USE_LINKER=lld \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
    -DCMAKE_INSTALL_PREFIX=/home/douliyang/large/mlir-workspace/mlir-aie/llvm/install


ninja -j $(nproc)

popd
```
the code should be turn into `.vscode/settings.json` and `.vscode/launch.json`.

`settings.json`
```json
{
    "cmake.generator": "Unix Makefiles",
    "cmake.configureSettings": {
        "CMAKE_BUILD_TYPE": "Debug",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "YES",
        "LLVM_DIR": "/home/douliyang/large/mlir-workspace/mlir-aie/build/lib/cmake/llvm",
        "MLIR_DIR": "/home/douliyang/large/mlir-workspace/mlir-aie/llvm/build/lib/cmake/mlir",
        "AIE_DIR": "/home/douliyang/large/mlir-workspace/mlir-aie/llvm/build/lib/cmake/aie",
        "LLVM_ENABLE_ASSERTIONS": "ON",
        "LLVM_USE_LINKER": "lld",
        "CMAKE_C_COMPILER": "/usr/local/bin/clang",
        "CMAKE_CXX_COMPILER": "/usr/local/bin/clang++",
        "CMAKE_INSTALL_PREFIX": "/home/douliyang/large/mlir-workspace/mlir-aie/llvm/install",
        "CMAKE_BUILD_PARALLEL_LEVEL": "32"
    },
    "cmake.environment": {
        "PATH": "/home/douliyang/large/mlir-workspace/mlir-aie/llvm/install/bin:${env:PATH}"
    },
}
```

`launch.json`
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug polyaie",
            "type": "cppdbg",
            "request": "launch",
            "program": "/home/douliyang/large/mlir-workspace/aie-compiler/build/bin/polyaie-opt", 
            "args": [
                "--polyaie-affine-preprocess", 
                "--affine-super-vectorize", 
                "--canonicalize",
                "/home/douliyang/large/mlir-workspace/aie-compiler/test/Conversion/scalar-memref.mlir"
            ],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "miDebuggerPath": "/usr/bin/gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "preLaunchTask": "build"  // This will reference a task for building before debugging
        }
    ]
}
```
then we can use vscode gui to debug our mlir codes.

## Advance cmake topic
refer to [modern cmake](https://hsf-training.github.io/hsf-training-cmake-webpage/)