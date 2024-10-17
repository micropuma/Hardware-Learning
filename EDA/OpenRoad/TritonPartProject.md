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

## 输入输出文件及存储数据结构  
首先明确该项目有多少输入文件：  

### Hypergraph

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

```shell
python regression.py | tee summary.log
```
修改regression.py文件：  
1. 比如没有hMetis的可执行，可以修改代码或是增添其他比对项目。
2. 修改参数：  

regression.py文件实现了如下功能：  
* hMetisEvaluator 是一个用于**评估超图划分结果的函数**。它的主要任务是根据给定的超图和划分解决方案，计算划分的质量，具体包括计算超边的切割代价（即被切割的超边的权重总和）和各个部分（块）的负载平衡。
    ```python
    num_cut = 0
    for i in range(num_hyperedges):
        part_list = []
        for vertex in hyperedges[i]:
            if(part[vertex] not in part_list):
                part_list.append(part[vertex])

        if(len(part_list) > 1):
            num_cut += hyperedges_weight[i]
    ```  
* 运行Partition程序，包括三部分：hmetis，khmetis和tritonpart。以TritonPart为例，是通过写tcl脚本来实现的。   
    ```cpp
    if (partitioner == "tritonpart"):
        cmd = "triton_part_hypergraph -hypergraph_file " + hypergraph_file + " "
        cmd += "-num_parts " + str(Nparts) + " "
        cmd += "-balance_constraint " + str(UBfactor) + " "
        cmd += "-seed " + str(seed)
        cmd += "\n"
        cmd += "exit\n"
        test_file = "run_openroad.tcl"
        f = open(test_file, "w")
        f.write(cmd)
        f.close()
        cmd = exe + " " + test_file
        os.system(cmd)
        cmd = "rm " + test_file
        os.system(cmd)
    ```
* 设定测试集和超级参数：  
    ```cpp
    # Setup benckmark list
    design_list = ["bitonic_mesh"]
                    #"cholesky_mc",
                    #"dart",
                    #"des90",
                    #"neuron",
                    #"openCV",
                    #"segmentation",
                    #"SLAM_spheric",
                    #"sparcT1_core",
                    #"stereo_vision"]

    # Setup sweep parameters
    UBfactor_list = [5, 10, 15, 20]
    Nparts_list = [2]
    Nruns = 3
    seed_list = list(range(Nruns))
    ```
* 设定可执行路径  
    ```cpp
    # Setup exe files
    tritonpart_exe = "../build/src/openroad"
    khmetis_exe = "../hMETIS/khmetis"
    hmetis_exe = "../hMETIS/hmetis"
    # Setup benchmark directory
    benchmark_dir = "../titan23_benchmark/"
    ```
* 运行代码主体  
    ```cpp  
    for Nparts in Nparts_list:
        for UBfactor in UBfactor_list:
            for design in design_list:
                print("[INFO] Running ", design, " with UBfactor ", UBfactor, " and Nparts ", Nparts)
                for seed in seed_list:
                    line = str(design) + "," + str(UBfactor) + "," + str(Nparts) + ","
                    line += str(seed) + ","
                    cutsize_list = []
                    for partitioner in partitioner_list:
                        print("[INFO] Running Partitioner : ", partitioner)
                        original_hypergraph_file = benchmark_dir + design + ".hgr"
                        hypergraph_file = work_dir[partitioner] + design + ".hgr"
                        cmd = "cp " + original_hypergraph_file + " " + hypergraph_file
                        os.system(cmd)
                        start_time = time.time()
                        RunPartitioner(partitioner, partitioner_exe[partitioner],
                                    hypergraph_file, Nparts, UBfactor, seed)
                        end_time = time.time()
                        runtime = round(end_time - start_time, 3)
                        original_solution_file = hypergraph_file + ".part." + str(Nparts)
                        solution_file = hypergraph_file +  ".k." + str(Nparts)
                        solution_file += ".UBfactor." + str(UBfactor)
                        solution_file += ".seed." + str(seed)
                        cmd = "mv  " + original_solution_file + " " + solution_file
                        os.system(cmd)
                        cutsize, balance = hMetisEvaluator(hypergraph_file, solution_file,
                                                        Nparts, UBfactor)
                        print("cutsize : ", cutsize)
                        print("balance : ", balance)
                        cutsize_list.append(cutsize)
                        line += str(runtime) + "," + str(cutsize) + ","
                        balance_str = "["
                        for value in balance:
                            balance_str += " " + str(value) + " "
                        balance_str += "]"
                        line += balance_str + ","
                    min_cutsize = min(cutsize_list)
                    min_idx = cutsize_list.index(min_cutsize)
                    line += str(min_cutsize) + "," + partitioner_list[min_idx]
                    f = open(summary_report, "a")
                    f.write(line + "\n")
                    f.close()
    ```
* Summary分析  
    ```cpp
    print("************************************************")
    print("************* Result Summary *******************")
    print('************************************************')
    print("\n")
    print("------------------------------------------------")
    print("--------- hMETIS VS TritonPart -----------------")
    print("Fail ratio of TritonPart : ", hmetis_win / num_runs, "% (", hmetis_win, "/", num_runs, ")")
    print("Average QoR degradation of TritonPart : ", hmetis_improve / hmetis_win)
    print("Win ratio of TritonPart : ", hmetis_fail / num_runs, "% (", hmetis_fail, "/", num_runs, ")")
    print("Average QoR improvement of TritonPart : ", hmetis_loss / hmetis_fail)
    print("Runtime of TritonPart : ", hmetis_runtime / num_runs)
    print("\n\n")
    print("------------------------------------------------")
    print("--------- khMETIS VS TritonPart -----------------")
    print("Fail ratio of TritonPart : ", khmetis_win / num_runs, "% (", khmetis_win, "/", num_runs, ")")
    print("Average QoR degradation of TritonPart : ", khmetis_improve / khmetis_win)
    print("Win ratio of TritonPart : ", khmetis_fail / num_runs, "% (", khmetis_fail, "/", num_runs, ")")
    print("Average QoR improvement of TritonPart : ", khmetis_loss / khmetis_fail)
    print("Runtime of TritonPart : ", khmetis_runtime / num_runs)
    ```

## 输入文件解读  


## 源码分析
### 代码框架解读  
> TritonPart的源代码在`/OpenRoad/src/part`下，头文件在`/OpenRoad/include`下面。TritonPart使用Cmake工具开发，所以阅读代码，写阅读`CMakeLists.txt`。

TritonPart的源代码大致可以分为如下几类：  
1. 工具类：
2. 命令行参数解析类：
3. driver类：
4. 实现具体算法：
5. dirver文件：`MakePartitionMgr.h`，`PartitionMgr.h`
6. 接口文件：`TritonPart.h`，`TritonPart.cpp`

### 参数配置
TritonPart项目的参数配置分为：  
1. 时序参数：`TritonPart::SetTimingParams()`
2. multi-level过程中的调参：`TritonPart::SetFineTuneParams()`

### 划分算法
有两个入口函数，分别是：
1. `TritonPart::PartitionHypergraph()` 完成hMetis的所用功能 
    * fixed vertices contraint 
    * community attributes
    * group_file constraints
    * placement information
2. `TritonPart::PartitionDesign()` 增加时序考量    
    * timing-driven partitioning

#### `TritonPart::PartitionHypergraph()` 
1. 先**读取HyperGraph文件**  
    ```cpp
    void TritonPart::ReadHypergraph(const std::string& hypergraph_file,
                                    const std::string& fixed_file,
                                    const std::string& community_file,
                                    const std::string& group_file,
                                    const std::string& placement_file)
    ```
    核心逻辑是读取传入的五个文件参数后，构造HyperGraph类。  
    ```cpp 
    // Build the original hypergraph first
    original_hypergraph_ = std::make_shared<Hypergraph>(vertex_dimensions_, hyperedge_dimensions_, placement_dimensions_, hyperedges_, vertex_weights_, hyperedge_weights_, fixed_attr_, community_attr_, placement_attr_, logger_);
    ```
2. 核心步骤：`MultiLevelPartition()`  
    跳转至[MultiLevel解读](#multilevel算法解读)
3. 写入结果：  
    ```cpp 
    // write the solution in hmetis format
    std::ofstream solution_file_output;
    solution_file_output.open(solution_file);
    for (auto part_id : solution_) {
        solution_file_output << part_id << std::endl;
    }   
    solution_file_output.close();
    ```

#### 时序驱动的划分算法：`TritonPart::PartitionDesign()`  
算法原理见[An Open-Source Constraints-Driven General Partitioning Multi-Tool for VLSI Physical Design](https://ieeexplore.ieee.org/document/10323975/)

## MultiLevel算法解读
```cpp
// Partition the hypergraph_ with the multilevel methodology
// the return value is the partitioning solution
void TritonPart::MultiLevelPartition()
```

`MultiLevel`是TritonPart，也是其他Partition算法的核心。简要流程如下：  
1. 设定缺省参数（比如边权重等参数）
2. 构造**评价类（GoldenEvaluator）**，平衡约束上下限等
3. 构造粗化，分割，细化类
4. 如果支持timing作为优化目标，初始化超图上的timing值

### 顶层构造函数
```cpp
// create the multi-level class
  auto tritonpart_mlevel_partitioner
      = std::make_shared<MultilevelPartitioner>(num_parts_,
                                                v_cycle_flag_,
                                                num_initial_solutions_,
                                                num_best_initial_solutions_,
                                                num_vertices_threshold_ilp_,
                                                max_num_vcycle_,
                                                num_coarsen_solutions_,
                                                seed_,
                                                tritonpart_coarsener,
                                                tritonpart_partitioner,
                                                k_way_fm_refiner,
                                                k_way_pm_refiner,
                                                greedy_refiner,
                                                ilp_refiner,
                                                tritonpart_evaluator,
                                                logger_);
```
上述顶层构造函数，分别有一个粗化器：`Coarsener`，一个分割器：`Partitioner`以及四种细化器：`Refiner`。构造方法分别如下：  
```cpp
// create the refinement classes
// We have four types of refiner
// (1) greedy refinement. try to one entire hyperedge each time
auto greedy_refiner = std::make_shared<GreedyRefine>(num_parts_,
                                                    refiner_iters_,
                                                    path_timing_factor_,
                                                    path_snaking_factor_,
                                                    max_moves_,
                                                    tritonpart_evaluator,
                                                    logger_);
```

```cpp
// (2) ILP-based partitioning (only for two-way since k-way ILP partitioning
// is too timing-consuming)
auto ilp_refiner = std::make_shared<IlpRefine>(num_parts_,
                                                refiner_iters_,
                                                path_timing_factor_,
                                                path_snaking_factor_,
                                                max_moves_,
                                                tritonpart_evaluator,
                                                logger_);
```

```cpp
// (3) direct k-way FM
auto k_way_fm_refiner = std::make_shared<KWayFMRefine>(num_parts_,
                                                        refiner_iters_,
                                                        path_timing_factor_,
                                                        path_snaking_factor_,
                                                        max_moves_,
                                                        total_corking_passes_,
                                                        tritonpart_evaluator,
                                                        logger_);
```

```cpp
// (4) k-way pair-wise FM
auto k_way_pm_refiner = std::make_shared<KWayPMRefine>(num_parts_,
                                                        refiner_iters_,
                                                        path_timing_factor_,
                                                        path_snaking_factor_,
                                                        max_moves_,
                                                        total_corking_passes_,
                                                        tritonpart_evaluator,
                                                        logger_);  
```

构造类实例化结束后，就开始做partition任务：  
1. coarsening phase
    ```cpp
    // Use coarsening to do preprocessing step
    // Build the hypergraph used to call multi-level partitioner
    // (1) remove single-vertex hyperedge
    // (2) remove lager hyperedge
    // (3) detect parallel hyperedges
    // (4) handle group information
    // (5) group fixed vertices based on each block
    // group vertices based on group_attr_
    // the original_hypergraph_ will be modified by the Group Vertices command
    // We will store the mapping relationship of vertices between
    // original_hypergraph_ and hypergraph_
    tritonpart_coarsener->SetThrCoarsenHyperedgeSizeSkip(global_net_threshold_);
    hypergraph_ = tritonpart_coarsener->GroupVertices(original_hypergraph_, group_attr_);
    tritonpart_coarsener->SetThrCoarsenHyperedgeSizeSkip(thr_coarsen_hyperedge_size_skip_);
    ```
    主体函数是`Coarsener.h`类的`GroupVertices()`方法。
2. partition phase
    ```cpp
    // partition on the processed hypergraph
    std::vector<int> solution = tritonpart_mlevel_partitioner->Partition(hypergraph_, upper_block_balance, lower_block_balance);
    ```
    主体函数是`Multilevel.h`类的`Partition()`方法。
3. refine phase  
    * 先将hypergraph的解（solution）转换为原始hypergraph的解（solution_），即将经过某些聚类或划分的超图中每个顶点的分区信息映射回到原始超图中对应的顶点上。
        ```cpp
        // Translate the solution of hypergraph to original_hypergraph_
        // solution to solution_
        solution_.clear();
        solution_.resize(original_hypergraph_->GetNumVertices());
        std::fill(solution_.begin(), solution_.end(), -1);
        for (int cluster_id = 0; cluster_id < hypergraph_->GetNumVertices();
            cluster_id++) {
            const int part_id = solution[cluster_id];
            for (const auto& v : hypergraph_->GetVertexCAttr(cluster_id)) {
            solution_[v] = part_id;
            }
        }
        ```
    * 做V-Cycle refine  
        ```cpp
        // Perform the last-minute refinement
        tritonpart_coarsener->SetThrCoarsenHyperedgeSizeSkip(global_net_threshold_);
        tritonpart_mlevel_partitioner->VcycleRefinement(original_hypergraph_, upper_block_balance, lower_block_balance, solution_);
        ```
    * 评估步骤  
        ```cpp 
        // evaluate on the original hypergraph
        // tritonpart_evaluator->CutEvaluator(original_hypergraph_, solution_, true);
        tritonpart_evaluator->ConstraintAndCutEvaluator(original_hypergraph_, solution_, ub_factor_, group_attr_, true);
        ```
        refine过程中，最重要的函数是`Multilevel.h`类中的`VcycleRefinement()`

    后续重点解读这三个phase各自的重点函数。

### `GroupVertices()`方法  
```cpp  
// create a coarser hypergraph based on specified grouping information
// for each vertex.
// each vertex has been map its group
// (1) remove single-vertex hyperedge
// (2) remove lager hyperedge
// (3) detect parallel hyperedges
// (4) handle group information
// (5) group fixed vertices based on each block
// group vertices based on group_attr and hgraph->fixed_attr_
HGraphPtr Coarsener::GroupVertices(
    const HGraphPtr& hgraph,
    const std::vector<std::vector<int>>& group_attr) const
{
  std::vector<int>
      vertex_cluster_id_vec;          // map current vertex_id to cluster_id
  Matrix<float> vertex_weights_c;     // cluster weight
  std::vector<int> community_attr_c;  // cluster community information
  std::vector<int> fixed_attr_c;      // cluster fixed attribute
  Matrix<float> placement_attr_c;     // cluster placement attribute

  // Cluster based group information
  ClusterBasedGroupInfo(hgraph,
                        group_attr,
                        vertex_cluster_id_vec,
                        vertex_weights_c,
                        community_attr_c,
                        fixed_attr_c,
                        placement_attr_c);

  // coarsen the input hypergraph based on vertex matching map
  auto clustered_hgraph = Contraction(hgraph,
                                      vertex_cluster_id_vec,
                                      vertex_weights_c,
                                      community_attr_c,
                                      fixed_attr_c,
                                      placement_attr_c);

  // update the timing cost of the clusterd_hgraph
  // hgraph will be updated here
  // For timing-driven flow,
  // we need to convert the slack information to related weight
  // Basically we will transform the path_timing_attr_ to path_timing_cost_,
  // and transform hyperedge_timing_attr_ to hyperedge_timing_cost_.
  // Then overlay the path weighgts onto corresponding weights
  if (hgraph->HasTiming()) {
    evaluator_->InitializeTiming(clustered_hgraph);
  }

  return clustered_hgraph;
}
```

上述代码中，比较重要的是`ClusterBasedGroupInfo()`和`Contraction()`。    
`ClusterBasedGroupInfo()`方法：
```cpp
// ClusterBasedGroupInfo：
// handle group information
// group fixed vertices based on each block
// group vertices based on group_attr and hgraph->fixed_attr_
// the community id of a group vertices is the maximum of the community id of
// all vertices the fixed block id of a group vertices is the maximum of the
// fixed block id of all vertices Two group will be merged if two groups share
// the same vertex All the fixed vertices in one block will be identified as the
// same group
```
> `ClusterBasedGroupInfo()`类的作用是处理图中关于“组（group）”和“固定顶点（fixed vertices）”的信息，并对这些顶点进行分组和合并。

`Contraction()`方法：  
```cpp
//  create the contracted hypergraph based on the vertex matching in
//  vertex_cluster_id_vec
```

### `Partition()`方法  
```cpp
// Main function
// here the hgraph should not be const
// Because our slack-rebudgeting algorithm will change hgraph
Partitions Partition(const HGraphPtr& hgraph,
                    const Matrix<float>& upper_block_balance,
                    const Matrix<float>& lower_block_balance) const;
```
* 步骤1: 使用不同的随机种子进行初始分区。
    在实验中，观察到增加 V-cycle 的次数对结果的提升效果有限，但不同随机种子会显著影响解决方案的质量。
* 步骤2: 运行cut-overlay clustering以增强解决方案。
* 步骤3: 进行引导 V-cycle。

> code tells everything! 

```cpp  
// Main implementation
// Step 1: run initial partitioning with different random seed
// Step 2: run cut-overlay clustering to enhance the solution
// Step 3: Guided v-cycle

// Step 1: run initial partitioning with different random seed
// In experiments, we observe that the benefits of increasing number of
// vcycles is very limited. However, the quality of solutions will change a
// lot with different random seed
Matrix<int> top_solutions;
float best_cost = std::numeric_limits<float>::max();
int best_solution_id = -1;
for (int id = 0; id < num_coarsen_solutions_; id++) {
coarsener_->IncreaseRandomSeed();
top_solutions.push_back(
    SingleLevelPartition(hgraph, upper_block_balance, lower_block_balance));
const float cost
    = evaluator_->CutEvaluator(hgraph, top_solutions.back(), false).cost;
if (cost <= best_cost) {
    best_cost = cost;
    best_solution_id = id;
}
}

logger_->info(PAR, 151, "Finish Candidate Solutions Generation");

// Step 2: run cut-overlay clustering to enhance the solution
std::vector<int> best_solution = CutOverlayILPPart(hgraph,
                                                    upper_block_balance,
                                                    lower_block_balance,
                                                    top_solutions,
                                                    best_solution_id);

logger_->info(
    PAR, 152, "Finish Cut-Overlay Clustering and Optimal Partitioning");

// Step 3: Guided v-cycle. Note that hgraph has been updated.
// The best_solution will be refined.
// The initial value of best solution will be used to guide the coarsening
// process and use as the initial solution
if (v_cycle_flag_ == true) {
VcycleRefinement(
    hgraph, upper_block_balance, lower_block_balance, best_solution);
}

logger_->info(PAR, 153, "Finish Vcycle Refinement");

return best_solution;
```

### `VcycleRefinement()`方法



## 论文中提到的算法源码解析  
### `CutOverlayILPPart`算法  
1. 先计算出哪些hyperedge被割了  
    ```cpp
    std::vector<bool> hyperedge_mask(hgraph->GetNumHyperedges(), false);
    for (const auto& solution : top_solutions) {
        for (int e = 0; e < hgraph->GetNumHyperedges(); e++) {
            if (hyperedge_mask[e] == true) {
                continue;  // This hyperedge has been cut
            }

            const auto range = hgraph->Vertices(e);
            const int block_id = solution[*range.begin()];
            for (const int vertex :
                boost::make_iterator_range(range.begin() + 1, range.end())) {
                if (solution[vertex] != block_id) {
                    hyperedge_mask[e] = true;
                    break;  // end this hyperedge
                }
            }
        }
    }
    ```
2. 计算去掉被割hyperedge后的连通分量  
    ```cpp  
    // detect the connected components and mask each connected component as a
    // cluster
    int cluster_id = -1;
    // map the initial optimal solution to the solution of clustered hgraph
    std::vector<int> init_solution;
    for (int v = 0; v < hgraph->GetNumVertices(); v++) {
        if (vertex_cluster_vec[v] == -1) {
        vertex_cluster_vec[v] = ++cluster_id;
        init_solution.push_back(top_solutions[best_solution_id][v]);
        lambda_detect_connected_components(v, cluster_id);
        }
    }

    const int num_clusters = cluster_id + 1;
    std::vector<std::vector<int>> cluster_attr;
    cluster_attr.reserve(num_clusters);
    for (int id = 0; id < num_clusters; id++) {
        std::vector<int> group_cluster{};
        cluster_attr.push_back(group_cluster);
    }
    for (int v = 0; v < hgraph->GetNumVertices(); v++) {
        cluster_attr[vertex_cluster_vec[v]].push_back(v);
    }
    ```
    上述代码完成了如下内容：  
    * 集群检测
    * 结果映射
    * 集群属性构建

    一个核心算法是`lambda_detect_connected_components()`，计算联通图：  
    ```cpp  
    // pre-order BFS to traverse the hypergraph
    auto lambda_detect_connected_components = [&](int v, int cluster_id) -> void {
        std::queue<int> wavefront;
        wavefront.push(v);
        while (wavefront.empty() == false) {
            const int u = wavefront.front();
            wavefront.pop();
            for (const int e : hgraph->Edges(u)) {
                if (hyperedge_mask[e] == true) {
                    continue;  // this hyperedge has been cut
                }
                for (const int v_nbr : hgraph->Vertices(e)) {
                    if (vertex_cluster_vec[v_nbr] == -1) {
                        vertex_cluster_vec[v_nbr] = cluster_id;
                        wavefront.push(v_nbr);
                    }
                }
            }
        }
    };
    ```
3. 利用ILP-parition算法  
    ```cpp 
    // Call ILP-based partitioning
    HGraphPtr clustered_hgraph = coarsener_->GroupVertices(hgraph, cluster_attr);
    logger_->info(
        PAR,
        157,
        "Cut-Overlay Clustering : num_vertices = {}, num_hyperedges = {}",
        clustered_hgraph->GetNumVertices(),
        clustered_hgraph->GetNumHyperedges());

    if (num_clusters <= num_vertices_threshold_ilp_) {
        partitioner_->Partition(clustered_hgraph,
                                upper_block_balance,
                                lower_block_balance,
                                init_solution,
                                PartitionType::INIT_DIRECT_ILP);
    } else {
        clustered_hgraph->SetCommunity(init_solution);
        init_solution = SingleCycleRefinement(
            clustered_hgraph, upper_block_balance, lower_block_balance);
    }
    ```
4. 将结果映射回原图：  
    ```cpp  
    // map the solution back to the original hypergraph
    for (int c_id = 0; c_id < clustered_hgraph->GetNumVertices(); c_id++) {
        const int block_id = init_solution[c_id];
        for (const auto& v : clustered_hgraph->GetVertexCAttr(c_id)) {
            optimal_solution[v] = block_id;
        }
    }

    logger_->info(PAR, 158, "Statistics of cut-overlay solution:");
    evaluator_->CutEvaluator(hgraph, optimal_solution, true);
    return optimal_solution;
    ```

## References
1. [TritonPart github项目](https://github.com/ABKGroup/TritonPart)
2. [OpenROAD github项目](https://github.com/The-OpenROAD-Project/OpenROAD/tree/master)
3. [OpenROAD 官网](https://openroad.readthedocs.io/en/latest/)
3. [OpenROAD build](https://openroad.readthedocs.io/en/latest/user/Build.html)
4. [OpenROAD partition manager官方文档]()
5. [TritonPart论文](https://ieeexplore.ieee.org/document/10323975/)