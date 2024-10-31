# AIE Hardware stuff 
## cross-compile on VCK190  
build VCK190的时候，由于/bin/sh默认的是Dash，所以构建失败。需要使用vckpage包管理修改默认为bash。可以先直接使用学长的aie环境，如下：  
```shell
# AIE
export VITIS_HOME=/usr/xilinx/Vitis/2023.2
export PLATFORM_REPO_PATHS=$VITIS_HOME/base_platforms
export SYSROOT_PATH=/usr/xilinx/petalinux/2023.2
export EDGE_COMMON_SW_PATH=/usr/xilinx/xilinx-versal-common-v2023.2
XRT_PATH=${SYSROOT_PATH}/sysroots/cortexa72-cortexa53-xilinx-linux/usr/include/xrt
export PATH=$PATH:${XRT_PATH}
```

## References  
1. [clang交叉编译官方文档](https://clang.llvm.org/docs/CrossCompilation.html)
2. [LLVM core library交叉编译文档](https://getting-started-with-llvm-core-libraries-zh-cn.readthedocs.io/zh-cn/latest/ch08.html)  
3. [github交叉编译教程](https://github.com/tuoxie007/play_with_llvm/blob/master/ch03.md)
4. [fpga tutorial](https://fpgaemu.readthedocs.io/en/latest/emulation.html)