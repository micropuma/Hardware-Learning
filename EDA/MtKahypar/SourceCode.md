# MtKahypar 源码解读 
## MtKahypar的亮点  
1. 可以对于partition做选项配置    
    * large-k
    * deterministic
    * default
    * quality
    * highest_quality
    
2. 提供三种目标函数，同时也可以自定义目标函数  
    * cut (Cut-Net Metric)
    * km1 (Connectivity Metric)
    * soed (Sum-of-exteranl-Degrees Metric)
    * Steiner Tree Metric  
3. MtHahyPar支持将超图映射到目标图    
    * 传统的划分目标函数在划分时不考虑**目标图的拓扑结构**，只关注如何最小化分块之间的切割边数或其他度量。  
    * 该段强调了通过**优化Steiner树度量**，可以更好地将（超）图的节点映射到目标图的节点上。  
    * **todo：可能可以添加constraint，限定？**

## 文件结构     
项目主体在`/mt-kahypar`中。  
```shell
├── application
│   ├── CMakeLists.txt
│   ├── git_revision.txt.in
│   └── mt_kahypar.cc.in
├── CMakeLists.txt
├── datastructures
├── definitions.h
├── macros.h
├── parallel
├── partition
│   ├── context.cpp
│   ├── context_enum_classes.cpp
│   ├── context_enum_classes.h
│   ├── context.h
│   ├── conversion.cpp
│   ├── conversion.h
│   ├── deep_multilevel.cpp
│   ├── deep_multilevel.h
│   ├── factories.h
│   ├── initial_partitioning
│   ├── mapping
│   ├── metrics.cpp
│   ├── metrics.h
│   ├── multilevel.cpp
│   ├── multilevel.h
│   ├── partitioner.cpp
│   ├── partitioner_facade.cpp
│   ├── partitioner_facade.h
│   ├── partitioner.h
│   ├── preprocessing
│   ├── recursive_bipartitioning.cpp
│   ├── recursive_bipartitioning.h
│   ├── refinement
│   │   ├── fm
│   │   ├── gains
│   │   ├── i_rebalancer.h
│   │   ├── i_refiner.h
│   │   ├── label_propagation
│   │   └── rebalancing
│   └── registries
└── utils
```    

项目的另一个部分：`lib`和`include`，是将MtKahyPar编译构建成库后，

上述是缩减的项目结构。可以看到，包含如下几块：  
1. coarse，initial partition以及refine three-level算法。  
2. data structure，micro等宏定义。  
3. application文件夹是函数入口。

## 源码解读  
由于需求是复用MtKahyPar，所以比较关注如下几块源码：   
* MtKahyPar的**输入输出**（自己的输入输出需求如何修改以满足MtKahyPar的hMetis格式要求）。
* **自定义目标函数**（官方github提供了说明文档，编写代码手动实现自定义目标函数的功能）。  

### 函数入口 `/mt-kahypar/application/mt_kahypar.cc.in`
1. 先看头文件：  
    ```cpp  
    #include "mt-kahypar/definitions.h"
    #include "mt-kahypar/io/command_line_options.h"
    #include "mt-kahypar/io/hypergraph_factory.h"
    #include "mt-kahypar/io/partitioning_output.h"
    #include "mt-kahypar/partition/partitioner_facade.h"
    #include "mt-kahypar/partition/registries/register_memory_pool.h"
    #include "mt-kahypar/partition/conversion.h"
    #include "mt-kahypar/partition/mapping/target_graph.h"
    #include "mt-kahypar/utils/cast.h"
    #include "mt-kahypar/utils/delete.h"
    #include "mt-kahypar/utils/randomize.h"
    #include "mt-kahypar/utils/utilities.h"
    #include "mt-kahypar/utils/exception.h"
    ```
    可以针对性地找感兴趣的模块：  
    * `io/`中是处理输入输出的模块。
    * `definitions.h`包含各种宏定义以及定义。
    * `partition/`是分割任务模块，是核心。
    * `utils`是一些工具    

2. 获取预设文件
    ```cpp
    static std::string getPresetFile(const Context& context) {
        switch ( context.partition.preset_type ) {
            case PresetType::deterministic: return std::string(MT_KAHYPAR_CONFIG_DIR) + "deterministic_preset.ini";
            case PresetType::large_k: return std::string(MT_KAHYPAR_CONFIG_DIR) + "large_k_preset.ini";
            case PresetType::default_preset: return std::string(MT_KAHYPAR_CONFIG_DIR) + "default_preset.ini";
            case PresetType::quality: return std::string(MT_KAHYPAR_CONFIG_DIR) + "quality_preset.ini";
            case PresetType::highest_quality: return std::string(MT_KAHYPAR_CONFIG_DIR) + "highest_quality_preset.ini";
            case PresetType::UNDEFINED: return "";
        }
    return "";
    }
    ```  
    > github官网建议使用--preset-type来预设定。  
3. 主程序入口  
    ```cpp
    int main(int argc, char* argv[]) {
        Context context(false);
        processCommandLineInput(context, argc, argv);
    ```
    创建上下文对象，并调用命令行解析函数。  
4. 检查预设文件，如果没有但是指定了预设类型，就加载该类型文件。  
    ```cpp
    if ( context.partition.preset_file == "" ) {
        if ( context.partition.preset_type != PresetType::UNDEFINED ) {
        // Only a preset type specified => load context from corresponding ini file
        context.partition.preset_file = getPresetFile(context);
        processCommandLineInput(context, argc, argv);
        } else {
        throw InvalidInputException("No preset specified");
        }
    }
    ```
5. 确定实例和分区类型  
    ```cpp 
    if (context.partition.instance_type == InstanceType::UNDEFINED) {
        context.partition.instance_type = to_instance_type(context.partition.file_format);
    }
    context.partition.partition_type = to_partition_c_type(context.partition.preset_type, context.partition.instance_type);
    ```  
    根据输入的文件格式，确定是图还是超图，并决定分区类型。  
6. 硬件和线程配置  
    ```cpp
    size_t num_available_cpus = HardwareTopology::instance().num_cpus();
    if (num_available_cpus < context.shared_memory.num_threads) {
        context.shared_memory.num_threads = num_available_cpus;
    }
    ```   
7. 读入超图  
    ```cpp  
    mt_kahypar_hypergraph_t hypergraph = io::readInputFile(
        context.partition.graph_filename, context.partition.preset_type, 
        context.partition.instance_type, context.partition.file_format, 
        context.preprocessing.stable_construction_of_incident_edges);
    ```  
8. 处理目标图（Optional）  
    ```cpp  
    if (context.partition.objective == Objective::steiner_tree) {
        target_graph = std::make_unique<TargetGraph>    (io::readInputFile<ds::StaticGraph>(
            context.mapping.target_graph_file, FileFormat::Metis, true));
    }
    ```  
9. **partition操作**  
    ```cpp  
    mt_kahypar_partitioned_hypergraph_t partitioned_hypergraph = PartitionerFacade::partition(hypergraph, context, target_graph.get());
    ```  
10. 打印输出分区和清理资源  

可以看到，设置的文件，参数，都存储在context上下文中。  

### 读入超图 


### 目标函数 
重点参考[如何实现自己的约束](https://github.com/kahypar/mt-kahypar/tree/master/mt-kahypar/partition/refinement/gains)。MtKahyPar项目作者为使用者提供了编写自己的目标函数的接口，支持不用修改项目内部逻辑就能完成优化目标。需要注意如下两条限制：  
1. 只能优化最小化问题。  
2. 目标函数只能定义在超边上。

#### 填加目标函数的步骤  


### 约束函数     
MtKahyPar有一个**target graph**这个概念。  

```cpp  
// Read Target Graph
std::unique_ptr<TargetGraph> target_graph;
if ( context.partition.objective == Objective::steiner_tree ) {
    if ( context.mapping.target_graph_file != "" ) {
        target_graph = std::make_unique<TargetGraph>(
        io::readInputFile<ds::StaticGraph>(
            context.mapping.target_graph_file, FileFormat::Metis, true));
    } else {
        throw InvalidInputException("No target graph file specified (use -g <file> or --target-graph-file=<file>)!");
    }
}
```
(todo: 完成target graph逻辑理解)

## Partition算法详细解读    
根据前面的app入口分析，`PartitionerFacade::partition`是Parition算法的入口。因此先重点关注 `/mt-kahaypar/partition/PartitionerFacade.h`等文件。    

### **PartionerFacade**完成如下工作：  
1. 配置和上下文管理
2. 封装划分逻辑  
3. 处理超图   

### 源码解读  
```cpp   
// ! Partition the hypergraph into a predefined number of blocks
static mt_kahypar_partitioned_hypergraph_t partition(mt_kahypar_hypergraph_t hypergraph, Context& context,
TargetGraph* target_graph = nullptr);

// ! Improves a given partition
static void improve(mt_kahypar_partitioned_hypergraph_t partitioned_hg, Context& context, TargetGraph* target_graph = nullptr);
```  

先重点理解`Partitioner<TypeTraits>::partition`，流程图如下：  

针对上述流程，讲解每个phase  
1. `configurePreprocessing(hypergraph, context)`:   
该函数根据图的结构特点，为社区检测选择合适的边权重函数，以优化社区划分效果。
稀疏图倾向于使用基于度的权重，稠密图则倾向于使用均匀的权重，而在中等稠密度情况下，如果超边的规模较大，使用非均匀权重。（**todo：边权重应该是固死的**）。
2. `setupContext(hypergraph, context, target_graph)`:  
各种初始化，初始化graph weight，初始化已有算法，初始化Steiner树算法，初始化fixed point集合。  
3. 后续代码很自然地分成三个部分：  
    * Preprocessing     
        1. `preprocess()`：目标是用community检测和Steiner树预计算来优化超图划分的准备工作。**由于`run_parallel_louvain`现成算法只能针对Graph做community检测，所以需要先`graph()`将已有的hypergraph构造成graph**。完成community检测后，需要将community映射回hypergraph上。
        2. `sanitize()`：对超图清理优化，去除度为零的超节点和大的超边。
    * Multilevel & V-cycle  
        ```cpp   
        PartitionedHypergraph partitioned_hypergraph;
        if (context.partition.mode == Mode::direct) {
            partitioned_hypergraph = Multilevel<TypeTraits>::partition(hypergraph, context, target_graph);
        } else if (context.partition.mode == Mode::recursive_bipartitioning) {
            partitioned_hypergraph = RecursiveBipartitioning<TypeTraits>::partition(hypergraph, context, target_graph);
        } else if (context.partition.mode == Mode::deep_multilevel) {
            ASSERT(context.partition.objective != Objective::steiner_tree);
            partitioned_hypergraph = DeepMultilevel<TypeTraits>::partition(hypergraph, context);
        } else {
            throw InvalidParameterException("Invalid partitioning mode!");
        }
        ```  
        Partition有三种模式：Multilevel，DeepMultilevel和RecursivePartition,详细见[Partition策略解读](#partition策略解读)。并在每一次Partition后检查是否满足fixed partition的约束。  

        ```cpp   
        ASSERT([&] {
            bool success = true;
            if ( partitioned_hypergraph.hasFixedVertices() ) {
                for ( const HypernodeID& hn : partitioned_hypergraph.nodes() ) {
                    if ( partitioned_hypergraph.isFixed(hn) &&
                        partitioned_hypergraph.fixedVertexBlock(hn) != partitioned_hypergraph.partID(hn) ) {
                        LOG << "Node" << hn << "is fixed to block" << partitioned_hypergraph.fixedVertexBlock(hn)
                            << ", but is assigned to block" << partitioned_hypergraph.partID(hn);
                        success = false;
                    }
                }
            }
            return success;
        }(), "Some fixed vertices are not assigned to their corresponding block");
        ```
    * Postprocessing    
        ```cpp  
        timer.start_timer("postprocessing", "Postprocessing");
        large_he_remover.restoreLargeHyperedges(partitioned_hypergraph);
        degree_zero_hn_remover.restoreDegreeZeroHypernodes(partitioned_hypergraph);
        forceFixedVertexAssignment(partitioned_hypergraph, context);
        timer.stop_timer("postprocessing");

        #ifdef KAHYPAR_ENABLE_STEINER_TREE_METRIC
        if ( map_partition_to_target_graph_at_the_end ) {
            ASSERT(target_graph);
            context.partition.objective = Objective::steiner_tree;
            timer.start_timer("one_to_one_mapping", "One-To-One Mapping");
            InitialMapping<TypeTraits>::mapToTargetGraph(
                partitioned_hypergraph, *target_graph, context);
            timer.stop_timer("one_to_one_mapping");
        }
        #endif
        ```

## Partition策略解读  
### 1. `Multilevel<TypeTraits>::partition()`
该函数定义在`/mt-kahypar/multilevel.h`中，在`/mt-kahypar/multilevel.cpp`中。
主函数是：  
```cpp  
template<typename TypeTraits>
typename Multilevel<TypeTraits>::PartitionedHypergraph Multilevel<TypeTraits>::partition(
  Hypergraph& hypergraph, const Context& context, const TargetGraph* target_graph) {
    PartitionedHypergraph partitioned_hg = multilevel_partitioning<TypeTraits>(hypergraph, context, target_graph, false);

    // ################## V-CYCLES ##################
    if ( context.partition.num_vcycles > 0 && context.type == ContextType::main ) {
        partitionVCycle(hypergraph, partitioned_hg, context, target_graph);
    }

    return partitioned_hg;
}
```   
该方法先是调用`multilevel_partitioning()`这个template方法，完成多级分区，然后调用`multilevel_partitioning()`完成V-cycle，在已有的partition上进一步优化。
  
1. 粗化过程：  
    ```cpp   
    std::unique_ptr<ICoarsener> coarsener = CoarsenerFactory::getInstance().createObject(
            context.coarsening.algorithm, utils::hypergraph_cast(hypergraph),
            context, uncoarsening::to_pointer(uncoarseningData));
    coarsener->coarsen();
    ```   
    多级分区函数调用template工厂方法得到对应的coarsener实例，再调用`i_coarsener.h`中的`coarsen()`函数：
    ```cpp
    void coarsen() {
        initialize();
        bool should_continue = true;
        // Coarsening algorithms proceed in passes where each pass computes a clustering
        // of the nodes and subsequently contracts it. Each pass induces one level of the
        // hierarchy. The coarsening algorithms proceeds until the number of nodes equals
        // a predefined contraction limit (!shouldNotTerminate) or the number of nodes could
        // not be significantly reduced within one coarsening pass (should_continue).
        while ( shouldNotTerminate() && should_continue ) {
        should_continue = coarseningPass();
        }
        terminate();
    }
    ```
2. initial parition阶段     
    ```cpp     
    // ################## INITIAL PARTITIONING ##################
    io::printInitialPartitioningBanner(context);
    timer.start_timer("initial_partitioning", "Initial Partitioning");
    PartitionedHypergraph& phg = uncoarseningData.coarsestPartitionedHypergraph();
    ```  
    上述的`coarsestPartitionedHypergraph()`就是获取最粗化情况下的graph。  

    ```cpp   
    if ( !is_vcycle ) {
        DegreeZeroHypernodeRemover<TypeTraits> degree_zero_hn_remover(context);
        if ( context.initial_partitioning.remove_degree_zero_hns_before_ip ) {
            degree_zero_hn_remover.removeDegreeZeroHypernodes(phg.hypergraph());
        }

        Context ip_context(context);
        ip_context.type = ContextType::initial_partitioning;
        ip_context.refinement = context.initial_partitioning.refinement;
        disableTimerAndStats(context);
        if ( context.initial_partitioning.mode == Mode::direct ) {
            // The pool initial partitioner consist of several flat bipartitioning
            // techniques. This case runs as a base case (k = 2) within recursive bipartitioning
            // or the deep multilevel scheme.
            ip_context.partition.verbose_output = false;
            Pool<TypeTraits>::bipartition(phg, ip_context);
        } else if ( context.initial_partitioning.mode == Mode::recursive_bipartitioning ) {
            RecursiveBipartitioning<TypeTraits>::partition(phg, ip_context, target_graph);
        } else if ( context.initial_partitioning.mode == Mode::deep_multilevel ) {
            ASSERT(ip_context.partition.objective != Objective::steiner_tree);
            ip_context.partition.verbose_output = false;
            DeepMultilevel<TypeTraits>::partition(phg, ip_context);
        } else {
            throw InvalidParameterException("Undefined initial partitioning algorithm");
        }
    ```  
    非V-CYCLE情况下，根据选择的parition策略，选择在最粗化情况下的初始划分算法。  
    V-CYCLE情况下，根据已有的partition，在每个分块内部做partition：  
    ```cpp   
    // When performing a V-cycle, we store the block IDs
    // of the input hypergraph as community IDs
    const Hypergraph& hypergraph = phg.hypergraph();
    phg.doParallelForAllNodes([&](const HypernodeID hn) {
        const PartitionID part_id = hypergraph.communityID(hn);
        ASSERT(part_id != kInvalidPartition && part_id < context.partition.k);
        ASSERT(phg.partID(hn) == kInvalidPartition);
        phg.setOnlyNodePart(hn, part_id);
    });
    phg.initializePartition();

    #ifdef KAHYPAR_ENABLE_STEINER_TREE_METRIC
    if ( context.partition.objective == Objective::steiner_tree ) {
        phg.setTargetGraph(target_graph);
        timer.start_timer("one_to_one_mapping", "One-To-One Mapping");
        // Try to improve current mapping
        InitialMapping<TypeTraits>::mapToTargetGraph(phg, *target_graph, context);
        timer.stop_time("one_to_one_mapping");
    }
    #endif
    ```  
    V-CYCLE的partition做了如下几步：  
    * 利用并行处理方式，对每个节点，获取其community id，表示之前的partition分区结果。
    * 调用`initializePartition()`，该函数底层有如下步骤：  
        1. `iniitalizeBlockWeights()`负责遍历所有节点，并计算节点所属分区综合  
        2. 用tbb::parallel_for提高处理效率。  
3. uncoarsen
    ```cpp   
    // ################## UNCOARSENING ##################
    io::printLocalSearchBanner(context);
    timer.start_timer("refinement", "Refinement");
    std::unique_ptr<IUncoarsener<TypeTraits>> uncoarsener(nullptr);
    if (uncoarseningData.nlevel) {
      uncoarsener = std::make_unique<NLevelUncoarsener<TypeTraits>>(
        hypergraph, context, uncoarseningData, target_graph);
    } else {
      uncoarsener = std::make_unique<MultilevelUncoarsener<TypeTraits>>(
        hypergraph, context, uncoarseningData, target_graph);
    }
    partitioned_hg = uncoarsener->uncoarsen();
    ```  
    根据上下文参数，选择是多层还是单层的细化器，并做细化操作。

## 粗化，初始划分，细化的最底层代码   
### coarsen phase  
`coarsen()`调用`coarseningPassImpl()`，具体调用的函数根据传入的模版参数而定。这里以`multilevel_coarener.h`为例。  
1. 先随机洗牌各个超节点顺序  
    ```cpp    
    _current_vertices.resize(current_hg.initialNumNodes());
    parallel::scalable_vector<HypernodeID> cluster_ids(current_hg.initialNumNodes());
    tbb::parallel_for(ID(0), current_hg.initialNumNodes(), [&](const HypernodeID hn) {
      ASSERT(hn < _current_vertices.size());
      // Reset clustering
      _current_vertices[hn] = hn;
      _matching_state[hn].store(STATE(MatchingState::UNMATCHED), std::memory_order_relaxed);
      _matching_partner[hn].store(hn, std::memory_order_relaxed);
      cluster_ids[hn] = hn;
      if ( current_hg.nodeIsEnabled(hn) ) {
        _cluster_weight[hn] = current_hg.nodeWeight(hn);
      }
    });
    ```    
    * ASSERT(hn < _current_vertices.size()) 确保索引有效。
    * _current_vertices[hn] 被设置为节点自身的 ID，表示重置。
    * _matching_state[hn] 被设置为未匹配状态（MatchingState::UNMATCHED）。
    * _matching_partner[hn] 设置为节点自身，表示初始状态下每个节点的匹配伙伴是它自己。
    * cluster_ids[hn] 也被设置为节点自身 ID。
    * 如果节点是启用状态，则 _cluster_weight[hn] 被设置为该节点的权重。
    
    `parallelShuffleVector()`函数支持多线程随机洗牌各个节点。
    ```cpp   
    if ( _enable_randomization ) {
      utils::Randomize::instance().parallelShuffleVector( _current_vertices, UL(0), _current_vertices.size());
    }
    ```    

2. 根据partition算法是否有fixed point限制，用两种不同算法做聚类：  
    ```cpp      
    const HypernodeID num_hns_before_pass =
        current_hg.initialNumNodes() - current_hg.numRemovedHypernodes();
    HypernodeID current_num_nodes = 0;
    if ( current_hg.hasFixedVertices() ) {
        current_num_nodes = performClustering<true>(current_hg, cluster_ids);
    } else {
        current_num_nodes = performClustering<false>(current_hg, cluster_ids);
    }
    DBG << V(current_num_nodes);
    ```  
    * 初始化聚类操作前数量。
    * 针对不同选项，做聚类操作。   

3. 执行收缩操作之前，检查聚类是否合法  
    * 聚类的cluster划分：  
        ```cpp   
        parallel::scalable_vector<HypernodeWeight> expected_weights(current_hg.initialNumNodes());
        // Verify that clustering is correct
        for ( const HypernodeID& hn : current_hg.nodes() ) {
            const HypernodeID u = hn;
            const HypernodeID root_u = cluster_ids[u];
            if ( root_u != cluster_ids[root_u] ) {
            LOG << "Hypernode" << u << "is part of cluster" << root_u << ", but cluster"
                << root_u << "is also part of cluster" << cluster_ids[root_u];
            return false;
            }
            expected_weights[root_u] += current_hg.nodeWeight(hn);
        }
        ```
    * 聚类的权重更新：   
        ```cpp   
        // Verify that cluster weights are aggregated correct
        for ( const HypernodeID& hn : current_hg.nodes() ) {
            const HypernodeID u = hn;
            const HypernodeID root_u = cluster_ids[u];
            if ( root_u == u && expected_weights[u] != _cluster_weight[u] ) {
                LOG << "The expected weight of cluster" << u << "is" << expected_weights[u]
                    << ", but currently it is" << _cluster_weight[u];
                return false;
            }
        }
        ```  

4. 根据step2的聚类操作，做收缩。  
    ```cpp  
    _timer.start_timer("contraction", "Contraction");
    // Perform parallel contraction
    _uncoarseningData.performMultilevelContraction(std::move(cluster_ids), false /* deterministic */, round_start);
    _timer.stop_timer("contraction");
    ```

coarsen阶段的两个核心：`performClustering()`和`performMultilevelContraction()`。  
  
#### 做聚类（mt-kahypar/mt-kahypar/partition/coarsening/multilevel_coarsener.h） 
```cpp 
// We iterate in parallel over all vertices of the hypergraph and compute its contraction partner.
// Matched vertices are linked in a concurrent union find data structure, that also aggregates
// weights of the resulting clusters and keep track of the number of nodes left, if we would
// contract all matched vertices.p
```  

使用 Intel TBB (Threading Building Blocks) 的并行算法 tbb::parallel_for 来执行图的聚类操作：
```cpp   
tbb::parallel_for(0U, current_hg.initialNumNodes(), [&](const HypernodeID id) {
    ASSERT(id < _current_vertices.size());
    const HypernodeID hn = _current_vertices[id];  
    if (current_hg.nodeIsEnabled(hn)) {
        // We perform rating if ...
        //  1.) The contraction limit of the current level is not reached
        //  2.) Vertex hn is not matched before  
        const HypernodeID u = hn;
        if (_matching_state[u] == STATE(MatchingState::UNMATCHED)) {
            if (current_num_nodes > hierarchy_contraction_limit) {
                const Rating rating = _rater.template rate<has_fixed_vertices>(...);  

                // 根据评级结果，将超节点 u（当前超节点）与目标超节点 v 进行匹配，更新相应的数据结构以反映这一变化，并确保线程安全性。  
                const HypernodeID v = rating.target;
                HypernodeID& local_contracted_nodes = contracted_nodes.local();
                matchVertices<has_fixed_vertices>(current_hg, u, v,
                cluster_ids, local_contracted_nodes, fixed_vertices); 

                // 多线程高效计算threshold方法。
            }
        }
    }
}
```

#### 做收缩 （mt-kahypar-leon/mt-kahypar/partition/coarsening/coarsening_commons.h）  
```cpp   
ASSERT(!is_finalized);
Hypergraph& current_hg = hierarchy.empty() ? _hg : hierarchy.back().contractedHypergraph();
ASSERT(current_hg.initialNumNodes() == communities.size());
Hypergraph contracted_hg = current_hg.contract(communities, deterministic);
const HighResClockTimepoint round_end = std::chrono::high_resolution_clock::now();
const double elapsed_time = std::chrono::duration<double>(round_end - round_start).count();
hierarchy.emplace_back(std::move(contracted_hg), std::move(communities), elapsed_time);
```   

上述算法用vector存储层级的收缩结果。利用hypergraph的`contract()`函数做contract，并存储结果在新的层级。
```cpp   
vec<Level<TypeTraits>> hierarchy;
```  

### Partition phase 
有三种parition，分别是`bipartition()`，`RecursiveBipartitioning()`，`DeepMultilevel<TypeTraits>::partition()`。  
以`bipartition()`为例：  
首先，把各种initialparitioning的选项存储如vector<std::tuple<InitialPartitioningAlgorithm, int, int>>中：  
```cpp   
// Push the runs of the different initial partitioning algorithms into a task list
for ( uint8_t i = 0; i < static_cast<uint8_t>(InitialPartitioningAlgorithm::UNDEFINED); ++i ) {
    if ( context.initial_partitioning.enabled_ip_algos[i] ) {
        auto algorithm = static_cast<InitialPartitioningAlgorithm>(i);
        for ( size_t j = 0; j < context.initial_partitioning.runs; ++j ) {
            // Each initial partitioning algorithm is assigned a seed and a tag
            // for deterministic behavior when partitioning in deterministic mode.
            _ip_task_lists.emplace_back(algorithm, rng(), tag++);
        }
    }
}
```    
每个paritioning algorithm都有一个seed和tag，一并存入vector中，来保证每次parition是**确定性**的。
在enum class中，给每种初始划分方法赋予了enum值：  
```cpp   
enum class InitialPartitioningAlgorithm : uint8_t {
  greedy_round_robin_fm = 0,
  greedy_global_fm = 1,
  greedy_sequential_fm = 2,
  random = 3,
  bfs = 4,
  label_propagation = 5,
  greedy_round_robin_max_net = 6,
  greedy_global_max_net = 7,
  greedy_sequential_max_net = 8,
  UNDEFINED = 9
};
```  
之后洗牌这些parition，并迭代取出各个partition task做操作：  
```cpp
for ( const auto& ip_task : _ip_task_lists ) {
    const InitialPartitioningAlgorithm algorithm = std::get<0>(ip_task);
    const int seed = std::get<1>(ip_task);
    const int tag = std::get<2>(ip_task);
    if ( run_parallel ) {
      tg.run([&, algorithm, seed, tag] {
        std::unique_ptr<IInitialPartitioner> initial_partitioner =
          InitialPartitionerFactory::getInstance().createObject(
            algorithm, algorithm, ip_data_ptr, context, seed, tag);
        initial_partitioner->partition();
      });
    } else {
      std::unique_ptr<IInitialPartitioner> initial_partitioner =
        InitialPartitionerFactory::getInstance().createObject(
          algorithm, algorithm, ip_data_ptr, context, seed, tag);
      initial_partitioner->partition();
    }
}  
```  
通过利用**工厂函数构**造出partitioner的实例，来做划分任务。和前面的coarsener实例通过`coarsenImpl()`调用具体的粗化器的粗化方法，partitioner最终也到`i_initial_partitioner.h`中的`partitionImpl()`函数。   

对比MultilevelPartition：  
```cpp   
template<typename TypeTraits>
typename TypeTraits::PartitionedHypergraph DeepMultilevel<TypeTraits>::partition(
  Hypergraph& hypergraph, const Context& context) {
  // TODO: Memory for partitioned hypergraph is not available at this point
  PartitionedHypergraph partitioned_hypergraph(
    context.partition.k, hypergraph, parallel_tag_t());
  partition(partitioned_hypergraph, context);
  return partitioned_hypergraph;
}
```  

上述函数将paritioned_hypergraph传递到`parition()`算法中。然后跟踪该partition算法：  
```cpp  
template<typename TypeTraits>
void DeepMultilevel<TypeTraits>::partition(PartitionedHypergraph& hypergraph, const Context& context) {
  RBTree rb_tree(context);
  deep_multilevel_partitioning<TypeTraits>(hypergraph, context,
    OriginalHypergraphInfo { hypergraph.totalWeight(),
      context.partition.k, context.partition.epsilon }, rb_tree);
}
```  
核心代码在`deep_multilevel.cpp`中的`deep_multilevel_partitioning()`函数中。改代码涵盖完整的coarsen()，initial_partition()以及uncoarsen()流程。  

chatgpt的解答：  
这段代码实现了超图的多级分区算法。下面我会详细解释每一行代码的含义和作用，帮助你理解整个算法的流程：
1. 上下文参数的设置和初始化
```cpp
  const Hypergraph& hypergraph = partitioned_hg.hypergraph();
  const bool detailed_output = context.partition.verbose_output;
  const HypergraphInfo* hypergraph_info = hypergraph.info();
  const double contraction_limit = context.coarsening.contraction_limit;
const Hypergraph& hypergraph = partitioned_hg.hypergraph();
```
从 partitioned_hg 对象中提取出原始的超图 hypergraph。partitioned_hg 是已经被分区的超图对象，而 hypergraph() 返回其中未分区的超图部分。
```cpp
const bool detailed_output = context.partition.verbose_output;
```
从 context 对象中获取 verbose_output 标志，表示是否需要详细输出调试信息。
```cpp
const HypergraphInfo* hypergraph_info = hypergraph.info();
```
获取超图的统计信息，比如超图的节点数、边数等。
```cpp
const double contraction_limit = context.coarsening.contraction_limit;
```
从上下文中获取粗化限制 contraction_limit，用于控制超图在粗化过程中的最小大小。

2. 粗化阶段的处理逻辑
```cpp
Copy code
  if (detailed_output) {
    LOG << "Start deep multilevel partitioning on" << o_info.num_nodes
        << "nodes and" << o_info.num_edges << "edges";
  }
```
如果 detailed_output 为 true，则打印超图初始的节点数和边数，作为分区过程的日志信息。
```cpp
  CoarsenerFactory coarsener_factory;
  std::unique_ptr<Coarsener> coarsener = coarsener_factory.create_coarsener(hypergraph, context);
  coarsener->initialize();
CoarsenerFactory coarsener_factory;
```
创建 CoarsenerFactory 对象，用来生成用于粗化超图的 Coarsener。
```cpp
std::unique_ptr<Coarsener> coarsener = coarsener_factory.create_coarsener(hypergraph, context);
```
使用工厂方法生成 Coarsener 对象，该对象根据 hypergraph 和 context 来执行具体的粗化策略。
```cpp
coarsener->initialize();
```
初始化粗化器，准备进行粗化操作。这一步会预处理超图，方便后续的粗化。

```cpp
  Hypergraph contracted_hg = hypergraph;
  while (contracted_hg.initial_num_nodes() > contraction_limit && coarsener->coarsen(contracted_hg)) {
    contracted_hg = coarsener->contracted_hypergraph();
    if (detailed_output) {
      LOG << "Coarsened to" << contracted_hg.initial_num_nodes() << "nodes";
    }
  }
```
Hypergraph contracted_hg = hypergraph;
创建 contracted_hg，这是粗化过程中使用的超图，最初它和原始超图 hypergraph 相同。
```cpp
while (contracted_hg.initial_num_nodes() > contraction_limit && coarsener->coarsen(contracted_hg)) {
```
这是粗化的主要循环：

当当前超图 contracted_hg 的节点数大于收缩限制 contraction_limit，并且可以继续进行粗化时，执行粗化操作。
coarsener->coarsen(contracted_hg) 尝试对当前超图进行粗化，成功返回 true。
contracted_hg = coarsener->contracted_hypergraph();
每次成功粗化后，更新 contracted_hg 为最新的粗化超图。

if (detailed_output)
如果启用了详细输出，则记录当前粗化后的节点数。

3. 判断是否需要递归进行分区
```cpp
  if (contracted_hg.initial_num_nodes() <= context.shared_memory.num_threads * 10) {
    deep_multilevel_partitioning(partitioned_hg, context, contracted_hg, o_info, tree);
    return;
  }
if (contracted_hg.initial_num_nodes() <= context.shared_memory.num_threads * 10)
```
如果超图的节点数降到了某个临界值（根据线程数的倍数决定），就递归调用 deep_multilevel_partitioning 函数对当前缩小的超图进行更细粒度的分区。
```cpp
deep_multilevel_partitioning(partitioned_hg, context, contracted_hg, o_info, tree);
```
递归调用自身，对粗化后的超图进行进一步分区。
递归调用完成后立即返回。

4. 初始分区的处理逻辑
```cpp
  if (coarsener->is_contraction_limit_reached()) {
    initial_bisection(contracted_hg, partitioned_hg, context);
  } else {
    deep_multilevel_partitioning(partitioned_hg, context, contracted_hg, o_info, tree);
  }
if (coarsener->is_contraction_limit_reached())
```
判断是否达到了收缩限制。如果是，表示超图已经被粗化到足够小，不能再进一步粗化。
```cpp
initial_bisection(contracted_hg, partitioned_hg, context);
```
调用 initial_bisection，对最小的粗化超图进行初始分区（二分）。
```cpp
else { deep_multilevel_partitioning(...) }
```
如果没有达到收缩限制，则递归调用自身，继续执行深度多级分区。

5. 解粗化和优化阶段
```cpp
  std::unique_ptr<Uncoarsener> uncoarsener = UncoarsenerFactory::create_uncoarsener(contracted_hg, partitioned_hg, context);
  uncoarsener->initialize();
  while (uncoarsener->uncoarsen()) {
    if (detailed_output) {
      LOG << "Uncoarsened to" << partitioned_hg.initial_num_nodes() << "nodes";
    }
  }
std::unique_ptr<Uncoarsener> uncoarsener = UncoarsenerFactory::create_uncoarsener(...);
```
创建 Uncoarsener 对象，Uncoarsener 用于将粗化的超图逐步恢复原始规模，同时在每个阶段对分区进行优化。
```cpp
uncoarsener->initialize();
```
初始化解粗化器，准备进行解粗化操作。
```cpp
while (uncoarsener->uncoarsen())
```
这是解粗化的主循环：每次恢复一部分超图，并优化分区，直到恢复到原始的超图。
```cpp
if (detailed_output)
```
如果启用了详细输出，记录每次解粗化后的节点数。
通过这段代码，我们可以看到该函数实现了一个典型的多级分区算法：它先通过粗化减少超图的规模，然后递归分区，最后通过解粗化逐步恢复原始规模，同时优化分区质量。这种方法适用于大规模超图的高效分区。

## 目标函数代码解读 
`deep_multilevel.cpp`中的选择最佳划分的函数。 
```cpp  
template<typename TypeTraits>
const DeepPartitioningResult<TypeTraits>& select_best_partition(
  const vec<DeepPartitioningResult<TypeTraits>>& partitions,
  const Context& context,
  const PartitionID k,
  const RBTree& rb_tree) {
  vec<HyperedgeWeight> objectives(partitions.size(), 0);
  vec<bool> isBalanced(partitions.size(), false);

  // Compute objective value and perform balance check for each partition
  tbb::task_group tg;
  for ( size_t i = 0; i < partitions.size(); ++i ) {
    tg.run([&, i] {
      objectives[i] = metrics::quality(
        partitions[i].partitioned_hg, context);
      isBalanced[i] = is_balanced(partitions[i].partitioned_hg, k, rb_tree);
    });
  }
  tg.wait();

  // We try to choose a balanced partition with the best objective value
  size_t best_idx = 0;
  for ( size_t i = 1; i < partitions.size(); ++i ) {
    if ( ( isBalanced[i] && !isBalanced[best_idx] ) ||
         ( ( ( !isBalanced[i] && !isBalanced[best_idx] ) ||
             ( isBalanced[i] && isBalanced[best_idx] ) ) &&
           objectives[i] < objectives[best_idx] ) ) {
      best_idx = i;
    }
  }

  return partitions[best_idx];
}
```

## References  
1. [MtKahyPar官方github仓库](https://github.com/kahypar/mt-kahypar)  
2. [目标函数官方文档](https://github.com/kahypar/mt-kahypar#supported-objective-functions)
3. [目标函数修改文档](https://github.com/kahypar/mt-kahypar#supported-objective-functions)
