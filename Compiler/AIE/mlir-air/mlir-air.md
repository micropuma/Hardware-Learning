# Dive deep into MLIR-AIR

## <font color = brown>Intro</font>

这个repo主要目标是深入`MLIR-AIR`项目，重点是理解：

* `mlir-air`的工具如何使用？
* `mlir-air`具体做了哪些工作？
* 基于`mlir-air`项目，还需要做哪些高层接入工作准备？



## <font color = brown>How to Use MLIR-AIR</font>

### <font color = green>AIRCC python wrapper</font>

和之前的`mlir-aie`项目提供的`aiecc.py`工具一样，`mlir-air`项目也是将整个的`optimization`和`transfromation`工作全部封装在`aircc.py`工具中。`mlir-air`提供详尽的说明文档：[docs/aircc.py](https://github.com/Xilinx/mlir-air/blob/main/docs/aircc.md)

> `aircc.py` is a compiler driver processing air programs. It takes the `AIR` MLIR dialect as input and produces AIE binaries plus host library code as output.
>
> 重点是：
>
> * 输入是`air 方言`的mlir文件
> * 输出是`aie`二进制以及host code
>
> 简言之：依旧无法打通一个**端到端**的流程。<font color = red>IREE项目其实接入的dialect就是AIR dialect</font>

利用`aircc.py --help`可以dump出`mlir-air`工具提供的功能：

```shell
usage: aircc [-h] [-o OUTPUT_FILE] [-i INSTS_FILE] [--tmpdir tmpdir] [-v] [-row-offset ROW_OFFSET]
             [-col-offset COL_OFFSET] [-num-rows NUM_ROWS] [-num-cols NUM_COLS]
             [-trace-size TRACE_SIZE] [-trace-offset TRACE_OFFSET] [-cc CC] [--sysroot sysroot]
             [--host-target host_target] [--shared] [-xbridge] [-xchesscc]
             [--device target_device] [--experimental-passes] [--omit-while-true-loop]
             [--omit-ping-pong-transform]
             air_mlir_file

positional arguments:
  air_mlir_file         AIR Dialect mlir file

options:
  -h, --help            show this help message and exit
  -o OUTPUT_FILE        Output filename
  -i INSTS_FILE         Output insts file name. Only used for compilation on an NPU.
  --tmpdir tmpdir       directory used for temporary file storage
  -v                    Trace commands as they are executed
  -row-offset ROW_OFFSET
                        Default row offset for generated segments
  -col-offset COL_OFFSET
                        Default column offset for generated segments
  -num-rows NUM_ROWS    Default number of rows for generated segments
  -num-cols NUM_COLS    Default number of rows for generated segments
  -trace-size TRACE_SIZE
                        Create packet routed traces for cores and memtiles
  -trace-offset TRACE_OFFSET
                        Trace buffer offset appended to output
  -cc CC                Compiler to use
  --sysroot sysroot     sysroot for cross-compilation
  --host-target host_target
                        Target architecture of the host program
  --shared              Generate a shared library (.so) instead of the default of a static library
                        (.a)
  -xbridge              pass --xbridge to aiecc, otherwise pass --no-xbridge
  -xchesscc             pass --xchesscc to aiecc, otherwise pass --no-xchesscc
  --device target_device
                        Target AIE device
  --experimental-passes
                        Whether to run experimental passes or not. This will only change the
                        behavior for this program for npu devices
  --omit-while-true-loop
                        By default, aircc may output a while(true) loop around per-core logic. If
                        this option is specified, a while(true) loop will not be added.
  --omit-ping-pong-transform
                        Whether to run passes which generate ping-pong buffering patterns or not.
                        This will only change the behavior for this program for npu devices
```

上述功能中，有如下几点我们比较感兴趣:

* `aircc.py`提供布局的约束，即可以指定`ROW_OFFSET`，`COL_OFFSET`，`NUM_ROWS`，`NUM_COLS`。对于此有如下疑问：
  1. 约束没法满足，`mlir-air`是如何处理的？
  2. 布局的优化手段是什么？
  3. 是否可以尝试自定义布局约束？<font color = red>可以考虑借鉴EDA划分算法？</font>
* 相比`aiecc.py`，似乎`aircc.py`是将host code编译成一个`.so`文件？需要double-check。
* `--omit-ping-pong-transform`对于ping-pong机制的了解不够深，需要deep dive。

在python binding场景下，如下使用即可：

```python
import air.compiler.aircc.main as aircc

# same as command line options above, but as a python list
aircc_options = ['air.mlir', '--shared', '-o', 'air.mlir.so']
aircc.run(air_module, aircc_options)
```

### <font color = green>AIR Dialect to code on Board</font>

![未命名文件 (11)](C:\Users\micro\Downloads\未命名文件 (11).png)

上述流程图阐述了完整的`aircc.py`如何把单一air输入文件，变成host和kernel各自可以部署到board上的代码。有如下几个特殊的点需要着重：

* `mlir-air`支持单一`.mlir`文件输入，并从中划分出`kernel code`和`host code`。
* `kernel code`需要生成`c++ configuation`的配置辅助文件，且该文件是针对每一个`partition`生成一个。
* `host code`需要`airrt dialect`的支持。

### <font color = green>An advanced example：GEMM</font>

这个例子来源于[mlir-air test/xrt/09](https://github.com/Xilinx/mlir-air/tree/main/test/xrt/09_gemm_extern_vec_4x4)，参考[docs/GEMM case study](https://github.com/Xilinx/mlir-air/blob/main/docs/GEMMCaseStudy.md)。

首先先来解读输入文件：

```cpp
#map = affine_map<()[s0] -> (s0 * 256)>
    #map1 = affine_map<()[s0] -> (s0 * 64)>
    #map2 = affine_map<()[s0] -> (s0 * 8)>
    #map3 = affine_map<(d0, d1, d2, d3, d4, d5) -> (d2, d0, d3, d5)>
    #map4 = affine_map<(d0, d1, d2, d3, d4, d5) -> (d1, d2, d5, d4)>
    #map5 = affine_map<(d0, d1, d2, d3, d4, d5) -> (d1, d0, d3, d4)>
    module {
      func.func @matmul_bf16(%0 : memref<512x1024xbf16>, %1 : memref<1024x512xbf16>, %2 : memref<512x512xbf16>) {
        %c4 = arith.constant 4 : index
        %c1 = arith.constant 1 : index
        %c2 = arith.constant 2 : index
        %c8 = arith.constant 8 : index
        %c128 = arith.constant 128 : index
        %c256 = arith.constant 256 : index
        %c1024 = arith.constant 1024 : index
        %cst = arith.constant 0.000000e+00 : bf16
        %c0 = arith.constant 0 : index
        scf.parallel (%arg0, %arg1) = (%c0, %c0) to (%c2, %c2) step (%c1, %c1) {
          %3 = affine.apply #map()[%arg0]
          %4 = affine.apply #map()[%arg1]
          %subview = memref.subview %2[%3, %4] [256, 256] [1, 1] : memref<512x512xbf16> to memref<256x256xbf16, strided<[512, 1], offset: ?>>
          %alloc = memref.alloc() : memref<256x1024xbf16, 1>
          scf.for %arg2 = %c0 to %c1024 step %c256 {
            %5 = affine.apply #map()[%arg0]
            %subview_2 = memref.subview %0[%5, %arg2] [256, 256] [1, 1] : memref<512x1024xbf16> to memref<256x256xbf16, strided<[1024, 1], offset: ?>>
            %subview_3 = memref.subview %alloc[0, %arg2] [256, 256] [1, 1] : memref<256x1024xbf16, 1> to memref<256x256xbf16, strided<[1024, 1], offset: ?>, 1>
            memref.copy %subview_2, %subview_3 : memref<256x256xbf16, strided<[1024, 1], offset: ?>> to memref<256x256xbf16, strided<[1024, 1], offset: ?>, 1>
          }
          %alloc_0 = memref.alloc() : memref<1024x256xbf16, 1>
          scf.for %arg2 = %c0 to %c1024 step %c256 {
            %5 = affine.apply #map()[%arg1]
            %subview_2 = memref.subview %1[%arg2, %5] [256, 256] [1, 1] : memref<1024x512xbf16> to memref<256x256xbf16, strided<[512, 1], offset: ?>>
            %subview_3 = memref.subview %alloc_0[%arg2, 0] [256, 256] [1, 1] : memref<1024x256xbf16, 1> to memref<256x256xbf16, strided<[256, 1], offset: ?>, 1>
            memref.copy %subview_2, %subview_3 : memref<256x256xbf16, strided<[512, 1], offset: ?>> to memref<256x256xbf16, strided<[256, 1], offset: ?>, 1>
          }
          %alloc_1 = memref.alloc() : memref<256x256xbf16, 1>
          scf.parallel (%arg2, %arg3) = (%c0, %c0) to (%c4, %c4) step (%c1, %c1) {
            %5 = affine.apply #map1()[%arg2]
            %6 = affine.apply #map1()[%arg3]
            %subview_2 = memref.subview %alloc_1[%5, %6] [64, 64] [1, 1] : memref<256x256xbf16, 1> to memref<64x64xbf16, strided<[256, 1], offset: ?>, 1>
            %alloc_3 = memref.alloc() : memref<16x16x4x4xbf16, 2>
            linalg.fill ins(%cst : bf16) outs(%alloc_3 : memref<16x16x4x4xbf16, 2>)
            scf.for %arg4 = %c0 to %c128 step %c8 {
              %7 = affine.apply #map1()[%arg2]
              %8 = affine.apply #map2()[%arg4]
              %subview_4 = memref.subview %alloc[%7, %8] [64, 64] [1, 1] : memref<256x1024xbf16, 1> to memref<64x64xbf16, strided<[1024, 1], offset: ?>, 1>
              %alloc_5 = memref.alloc() : memref<8x16x4x8xbf16, 2>
              %expand_shape = memref.expand_shape %subview_4 [[0, 1], [2, 3]] output_shape [16, 4, 8, 8] : memref<64x64xbf16, strided<[1024, 1], offset: ?>, 1> into memref<16x4x8x8xbf16, strided<[4096, 1024, 8, 1], offset: ?>, 1>
              %transpose_6 = memref.transpose %expand_shape (d0, d1, d2, d3) -> (d2, d0, d1, d3) : memref<16x4x8x8xbf16, strided<[4096, 1024, 8, 1], offset: ?>, 1> to memref<8x16x4x8xbf16, strided<[8, 4096, 1024, 1], offset: ?>, 1>
              air.dma_memcpy_nd (%alloc_5[] [] [], %transpose_6[] [] []) : (memref<8x16x4x8xbf16, 2>, memref<8x16x4x8xbf16, strided<[8, 4096, 1024, 1], offset: ?>, 1>)
              %9 = affine.apply #map2()[%arg4]
              %10 = affine.apply #map1()[%arg3]
              %subview_7 = memref.subview %alloc_0[%9, %10] [64, 64] [1, 1] : memref<1024x256xbf16, 1> to memref<64x64xbf16, strided<[256, 1], offset: ?>, 1>
              %alloc_8 = memref.alloc() : memref<16x8x8x4xbf16, 2>
              %expand_shape_9 = memref.expand_shape %subview_7 [[0, 1], [2, 3]] output_shape [8, 8, 16, 4] : memref<64x64xbf16, strided<[256, 1], offset: ?>, 1> into memref<8x8x16x4xbf16, strided<[2048, 256, 4, 1], offset: ?>, 1>
              %transpose_10 = memref.transpose %expand_shape_9 (d0, d1, d2, d3) -> (d2, d0, d1, d3) : memref<8x8x16x4xbf16, strided<[2048, 256, 4, 1], offset: ?>, 1> to memref<16x8x8x4xbf16, strided<[4, 2048, 256, 1], offset: ?>, 1>
              air.dma_memcpy_nd (%alloc_8[] [] [], %transpose_10[] [] []) : (memref<16x8x8x4xbf16, 2>, memref<16x8x8x4xbf16, strided<[4, 2048, 256, 1], offset: ?>, 1>)
              linalg.generic {indexing_maps = [#map3, #map4, #map5], iterator_types = ["parallel", "parallel", "reduction", "parallel", "parallel", "reduction"], library_call = "matmul_bf16_bf16"} ins(%alloc_5, %alloc_8 : memref<8x16x4x8xbf16, 2>, memref<16x8x8x4xbf16, 2>) outs(%alloc_3 : memref<16x16x4x4xbf16, 2>) {
              ^bb0(%in: bf16, %in_11: bf16, %out: bf16):
                %11 = arith.mulf %in, %in_11 : bf16
                %12 = arith.addf %out, %11 : bf16
                linalg.yield %12 : bf16
              }
              memref.dealloc %alloc_5 : memref<8x16x4x8xbf16, 2>
              memref.dealloc %alloc_8 : memref<16x8x8x4xbf16, 2>
            }
            %transpose = memref.transpose %alloc_3 (d0, d1, d2, d3) -> (d1, d2, d0, d3) : memref<16x16x4x4xbf16, 2> to memref<16x4x16x4xbf16, strided<[16, 4, 256, 1]>, 2>
            air.dma_memcpy_nd (%subview_2[] [] [], %transpose[] [] []) : (memref<64x64xbf16, strided<[256, 1], offset: ?>, 1>, memref<16x4x16x4xbf16, strided<[16, 4, 256, 1]>, 2>)
            memref.dealloc %alloc_3 : memref<16x16x4x4xbf16, 2>
            scf.reduce 
          }
          memref.copy %alloc_1, %subview : memref<256x256xbf16, 1> to memref<256x256xbf16, strided<[512, 1], offset: ?>>
          memref.dealloc %alloc : memref<256x1024xbf16, 1>
          memref.dealloc %alloc_0 : memref<1024x256xbf16, 1>
          memref.dealloc %alloc_1 : memref<256x256xbf16, 1>
          scf.reduce 
        }
        return
      }
    }
```

上述文件有如下特点：

* 支持的dialect有：`scf`，`memref`，`linalg`以及`air.dma_memcpy_nd`。
* 提供的文件已经识别出可以并行的点：`scf.parallel`或是`scf.forall`。

在tutorial中，提供一个很详细的流程，可以仔细研究，本文只是解读几个重点pass。

首先，我们可以将pass分成几个大类：

| Compilation Stage                     | Passes                                                       | Description                                                  |
| ------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Convert to MLIR-AIR                   | `air-linalg-to-func{link-with=mm.o}``air-par-to-herd{depth=1}``air-par-to-launch{has-air-segment=true}``air-copy-to-dma` | Binding parallelizable loops to `air` hierarchies; binding data movement operations to `air.dma_memcpy_nd` operations; binding linear algebra compute operations with link to AIE core kernel. |
| Asynchronous dependency analysis      | `air-dependency``air-dependency-canonicalize`                | Construction of asynchronous task graph, as an explicit representation of the asynchronous concurrency in the hardware schedule. |
| Broadcast                             | `air-dependency-schedule-opt``air-specialize-dma-broadcast`  | Detection and lowering of broadcasting data movement to map to circuit-routed streaming interconnects. |
| Generate half-dma operations          | `air-dma-to-channel`                                         | Lowering synchronous or asynchronous `air.dma_memcpy_nd` operations to `air.channel.put` or `air.channel.get` operations representing half-dma data sends and receives. |
| Outline L2 memrefs to memtile buffers | `func.func(air-split-l2-memref)`                             | Tiling L2 memrefs based on parallelizable data movements, explicitly represented via `scf.parallel` or `air.channel.put/get` operations, in order to maximize memtile bandwidth utilization. |
| Memtile DMA BD Optimization           | `air-isolate-async-dma-loop-nests``func.func(air-loop-fusion)``air-specialize-channel-wrap-and-stride` | Lowering L2 control flow program into finite-state machines made of Block Descriptors as states. |
| Double buffering                      | `air-label-scf-for-to-ping-pong``air-ping-pong-transform{keep-memref-dealloc=true}` | Detecting and lowering double buffering opportunities by analyzing data production and consumption patterns to a `memref` within an `scf.for` loop; explicitly represent the multiple asynchronous threads traversing through the loop. |
| Outline air.herd to aie.tiles         | `func.func(air-collapse-herd{max-col-size=4})``air-place-herds{num-rows=4 num-cols=4 row-anchor=2 col-anchor=0}``func.func(air-renumber-dma)` | Reshaping and placing `air.herd` onto `air.segment`; inferring `air.segment` shape and size. |
| Convert MLIR-AIR to MLIR-AIE          | `func.func(air-renumber-dma)``air-to-aie{row-offset=2 col-offset=0 device=npu1_4col emit-while-loop=true}` | Converting to MLIR-AIE dialect. Clone the `func.func` op, where one copy lowers to the circuit design to be mapped onto AIE tiles, and the other copy lowers to LX6 control program; outline `air.herd` body into `aie.core` kernel; materialize asynchronous `air.channel.put/get` into dma block descriptors and `aie.lock`. |
| SHIM DMA BD Optimization              | `air-to-std``func.func(affine-loop-opt{affine-opt-tile-sizes=4,4})``func.func(air-unroll-outer-affine-loops{depth=2})``airrt-to-npu` | Converting the control code via AIRRt and AIEX.NPU dialect to NPU SHIM DMA instruction sequence. |

上述表格描述清楚了基础的pass流程，以及pass分类。具体细节参考[GEMM case study](https://github.com/Xilinx/mlir-air/blob/main/docs/GEMMCaseStudy.md)即可。

* 生成`Herd`，`Segment`等抽象。

* 将memcopy机制改成`dma_mem_cpy`，这样不用和host的memory做交互。

* 将上述得到的ir，变成**异步的控制流和计算流分离**。

  ![image-20241221141927907](C:\Users\micro\AppData\Roaming\Typora\typora-user-images\image-20241221141927907.png)

  1. `air.execute`中承载了所有的计算workload。
  2. 利用`async_token`以及`air.wait_all`机制，来进行同步。

  ![image-20241221142200254](C:\Users\micro\AppData\Roaming\Typora\typora-user-images\image-20241221142200254.png)

  对于`segment`等抽象，该pass也能够支持细粒度的异步控制，从而提高资源利用率和执行效率。

  ![image-20241221142314124](C:\Users\micro\AppData\Roaming\Typora\typora-user-images\image-20241221142314124.png)上述其实对于这个pass的作用已经做了很好的阐述，即<font color = red>可以更好地利用Dataflow架构</font>，而不是依赖于host来做控制。

  举一个简单的内存初始化和数据处理例子：

  ```cpp
  %async_token_25, %results_26 = air.execute -> (memref<32x1024xi32, 1>) {
      %alloc = memref.alloc() : memref<32x1024xi32, 1>
      air.execute_terminator %alloc : memref<32x1024xi32, 1>
    }
    %async_token_27, %results_28 = air.execute -> (memref<32x1024xi32, 1>) {
      %alloc = memref.alloc() : memref<32x1024xi32, 1>
      air.execute_terminator %alloc : memref<32x1024xi32, 1>
    }
    ...
    %34 = scf.for %arg7 = %c0_22 to %c1024_23 step %c256_24 iter_args(%arg8 = %async_token_25) -> (!air.async.token) {
      %73 = air.channel.get async [%arg8]  @channel_12[%c0_22, %c0_22] (%results_26[%c0_22, %arg7] [%c32_18, %c256_24] [%c1024_23, %c1_19]) {id = 13 : i32} : (memref<32x1024xi32, 1>)
      scf.yield %73 : !air.async.token
    }
    %35 = scf.for %arg7 = %c0_22 to %c1024_23 step %c256_24 iter_args(%arg8 = %async_token_27) -> (!air.async.token) {
      %73 = air.channel.get async [%arg8]  @channel_12[%c1_19, %c0_22] (%results_28[%c0_22, %arg7] [%c32_18, %c256_24] [%c1024_23, %c1_19]) {id = 14 : i32} : (memref<32x1024xi32, 1>)
      scf.yield %73 : !air.async.token
    }
  ```

  1. 两个循环分别依赖于`%async_token_27`和`%async_token_25`。

* 基于上述的异步模式，`mlir-air`接下来尝试去发现潜在的`broadcast`模式，从而**减少数据传输开销**，提高并行性。

  

## <font color = brown>What MLIR-AIR provides？</font>

### <font color = green>Memory Hierarchy：herd，segment，launch</font>



### <font color = green>AIR runtime dialect</font>



### <font color = green>Async scheduling</font>

该部分主要参考[mlir-air async 文档](https://github.com/Xilinx/mlir-air/blob/main/docs/AIRAsyncConcurrency.md)。

![image-20241221144707969](C:\Users\micro\AppData\Roaming\Typora\typora-user-images\image-20241221144707969.png)

上述是对于`mlir-air`提供的`Async secheduling`的详细描述，可以看到，`CDFG`概念是重点。

#### CDFG abstraction

具体细节参考[CDFG slides](https://www.yumpu.com/en/document/view/15746966/control-data-flow-graph-cdfg-o-combines-dfg-and-cfg-o-often-)。

![image-20241221144956967](C:\Users\micro\AppData\Roaming\Typora\typora-user-images\image-20241221144956967.png)

#### 编译流程

![image-20241221145522158](C:\Users\micro\AppData\Roaming\Typora\typora-user-images\image-20241221145522158.png)

上述是几个和`CDFG`相关的编译pass选项。

* 从输入的mlir文件中提取出**CDFG**模型。即将**同步模式**变成**异步模式**。

  ![image-20241221150526227](C:\Users\micro\AppData\Roaming\Typora\typora-user-images\image-20241221150526227.png)

  ![image-20241221150605926](C:\Users\micro\AppData\Roaming\Typora\typora-user-images\image-20241221150605926.png)

  上述代码中，生成了token：`%4`，`%5`，`%6`，同时也depend on token：`async_token_12`等。

* 对于async代码做标准化。

  ![image-20241221150739659](C:\Users\micro\AppData\Roaming\Typora\typora-user-images\image-20241221150739659.png)

  可以尝试dump CDFG graph：

  ![image-20241221150819827](C:\Users\micro\AppData\Roaming\Typora\typora-user-images\image-20241221150819827.png)

* 利用`-air-dependency-schedule-opt`做优化

  ![image-20241221150907101](C:\Users\micro\AppData\Roaming\Typora\typora-user-images\image-20241221150907101.png)

  其原理是：

  * 利用mlir的attribute机制标记出可能的`broadcast pattern`。
  * 利用`affine map`来指导`broadcast`的内存模型。

  ![image-20241221151031473](D:\LeonDou\study\系统\mlir-aie\notes\End-to-End\iree\image-20241221151031473.png)

  上述机制中，`s[0]`是源内存，而`d0, d1`是目标位置。

  ![image-20241221151139705](C:\Users\micro\AppData\Roaming\Typora\typora-user-images\image-20241221151139705.png)

  `broadcast_pattern` 机制在这段代码中是用来控制数据传输时的映射关系，确保在不同维度上数据能够正确地对齐。



## <font color = brown>Some typical and outstanding passes in MLIR-AIR</font>

### <font color = green>Spatial partition</font>



### <font color = green>Ping-pong</font>





## <font color = brown>Further Steps？</font>