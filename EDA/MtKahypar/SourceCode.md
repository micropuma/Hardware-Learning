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
### `Multilevel<TypeTraits>::partition`

### `RecursiveBipartitioning<TypeTraits>::partition`

### `DeepMultilevel<TypeTraits>::partition`

## References  
1. [MtKahyPar官方github仓库](https://github.com/kahypar/mt-kahypar)  
2. [目标函数官方文档](https://github.com/kahypar/mt-kahypar#supported-objective-functions)
3. [目标函数修改文档](https://github.com/kahypar/mt-kahypar#supported-objective-functions)
