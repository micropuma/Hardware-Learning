# AIR build
## Bugs
在构建过程中，有如下tips：
1. 一定更新到最新的mlir-air版本，不然会出现`mlir`，`mlir-aie`和`mlir-air`代码版本冲突问题。
2. 构建`mlir-aie`过程中，使用`mlir-aie`项目提供的`build-mlir-aie-pcie.sh`脚本，该脚本可以快速构建`ROCr`，`ROCt`和`libxaiengine`三个子项目依赖。如果全手动构建而不依赖脚本，可能会出现cmake找不到对应项目的config的问题。
3. 需要修改`mlir-air`虚拟环境，参考`mlir-aie`虚拟环境配置，确保`mlir-python-extras`的支持。

## References
1. [AIR构建指南](https://xilinx.github.io/mlir-air/buildingVCK5000.html)
2. [MLIR-AIR dly version](https://github.com/micropuma/mlir-air)