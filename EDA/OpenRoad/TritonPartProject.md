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

## Benchmark
> 项目维护问题，test文件夹下的.sh文件的可执行文件路径应该修改为：../build/src/openroad run_openroad.tcl | tee run.log
 
TritonPart项目通过运行编译出的`openroad`可执行文件，去执行tcl脚本。如下是tcl的help，其中[]内的是可选，其他为必须。`triton_part_hypergraph`具体是什么，需要参考`OpenROAD/src/par/src/partitionmgr.tcl`文件。该文件中还有很多此类的**参数配置函数**。
```shell
triton_part_hypergraph
    -hypergraph_file hypergraph_file  
    -num_parts num_parts  
    -balance_constraint balance_constraint 
    [-base_balance base_balance]
    [-scale_factor scale_factor]
    [-seed seed] 
    [-vertex_dimension vertex_dimension] 
    [-hyperedge_dimension hyperedge_dimension] 
    [-placement_dimension placement_dimension] 
    [-fixed_file fixed_file] 
    [-community_file community_file] 
    [-group_file group_file] 
    [-placement_file placement_file] 
    [-e_wt_factors e_wt_factors] 
    [-v_wt_factors <v_wt_factors>] 
    [-placement_wt_factors <placement_wt_factors>]
    [-thr_coarsen_hyperedge_size_skip thr_coarsen_hyperedge_size_skip] 
    [-thr_coarsen_vertices thr_coarsen_vertices] 
    [-thr_coarsen_hyperedges thr_coarsen_hyperedges] 
    [-coarsening_ratio coarsening_ratio] 
    [-max_coarsen_iters max_coarsen_iters] 
    [-adj_diff_ratio adj_diff_ratio] 
    [-min_num_vertices_each_part min_num_vertices_each_part] 
    [-num_initial_solutions num_initial_solutions] 
    [-num_best_initial_solutions num_best_initial_solutions] 
    [-refiner_iters refiner_iters] 
    [-max_moves max_moves] 
    [-early_stop_ratio early_stop_ratio] 
    [-total_corking_passes total_corking_passes] 
    [-v_cycle_flag v_cycle_flag ] 
    [-max_num_vcycle max_num_vcycle] 
    [-num_coarsen_solutions num_coarsen_solutions] 
    [-num_vertices_threshold_ilp num_vertices_threshold_ilp] 
    [-global_net_threshold global_net_threshold] 
```

一个简单的运行example：  
```shell
../build/src/openroad run_openroad.tcl | tee run.log 
```

### [Titan23 benchmark](https://www.google.com/search?q=Titan23&oq=Titan23&gs_lcrp=EgZjaHJvbWUyBggAEEUYOTIHCAEQABiABDIMCAIQLhgKGIAEGOUEMgkIAxAAGAoYgAQyBwgEEAAYgAQyBwgFEAAYgAQyBwgGEAAYgAQyBggHEEUYPNIBCDIxMDlqMGo0qAIAsAIB&sourceid=chrome&ie=UTF-8)
Titan23 benchmark是以**cut size作为最重要的衡量手段**。`/regression`文件夹下的`regression.py`文件，可以跑hMetis，kMetis以及TritonPart的回归测试。


## 源码分析
### 代码框架解读  
> TritonPart的源代码在`/OpenRoad/src/part`下。TritonPart使用Cmake工具开发，所以阅读代码，写阅读`CMakeLists.txt`。

TritonPart的源代码大致可以分为如下几类：  
1. 工具类：
2. 命令行参数解析类：
3. driver类：
4. 实现具体算法：


## References
1. [TritonPart github项目](https://github.com/ABKGroup/TritonPart)
2. [OpenROAD github项目](https://github.com/The-OpenROAD-Project/OpenROAD/tree/master)
3. [OpenROAD 官网](https://openroad.readthedocs.io/en/latest/)
3. [OpenROAD build](https://openroad.readthedocs.io/en/latest/user/Build.html)
4. [OpenROAD partition manager官方文档]()