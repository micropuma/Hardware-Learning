# AIE project   
此项目记录了AIE平台编译链的相关文档。
## Structure of repo  
1. `poly-aie`   
    hanchenye构建的C/C++ lower到mliraie，借助于mlir-aie完成C/C++到VERSAL平台的编译链。
2. `iree`   
    IREE是一个是一个开源项目，旨在为机器学习（ML）和其他计算密集型应用提供高效的运行时和编译器支持。支持将诸如pytorch，tensorflow，onnx等高级语言lower到各种硬件资源上，包括：CUDA，ROCM，而AMD AIE处于实验阶段。
3. `mlir-aie`  
    mlir-aie项目定义了aie dialect，将一个logical dialect成功lower到llvm+intrinsic并build成elf和exe文件，在VERSAL等平台上运行。