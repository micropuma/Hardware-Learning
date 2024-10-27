# 自定义目标函数    
## 文件结构：
```shell  
├── bipartitioning_policy.h
├── cut
│   ├── cut_attributed_gains.h
│   ├── cut_flow_network_construction.h
│   ├── cut_gain_cache.cpp
│   ├── cut_gain_cache.h
│   ├── cut_gain_computation.h
│   └── cut_rollback.h
├── cut_for_graphs
│   ├── cut_attributed_gains_for_graphs.h
│   ├── cut_gain_cache_for_graphs.cpp
│   └── cut_gain_cache_for_graphs.h
├── gain_cache_ptr.h
├── gain_computation_base.h
├── gain_definitions.h
├── km1
│   ├── km1_attributed_gains.h
│   ├── km1_flow_network_construction.h
│   ├── km1_gain_cache.cpp
│   ├── km1_gain_cache.h
│   ├── km1_gain_computation.h
│   └── km1_rollback.h
├── README.md
├── soed
│   ├── soed_attributed_gains.h
│   ├── soed_flow_network_construction.h
│   ├── soed_gain_cache.cpp
│   ├── soed_gain_cache.h
│   ├── soed_gain_computation.h
│   └── soed_rollback.h
├── steiner_tree
│   ├── steiner_tree_attributed_gains.h
│   ├── steiner_tree_flow_network_construction.cpp
│   ├── steiner_tree_flow_network_construction.h
│   ├── steiner_tree_gain_cache.cpp
│   ├── steiner_tree_gain_cache.h
│   ├── steiner_tree_gain_computation.h
│   └── steiner_tree_rollback.h
└── steiner_tree_for_graphs
    ├── steiner_tree_attributed_gains_for_graphs.h
    ├── steiner_tree_flow_network_construction_for_graphs.cpp
    ├── steiner_tree_flow_network_construction_for_graphs.h
    ├── steiner_tree_gain_cache_for_graphs.cpp
    ├── steiner_tree_gain_cache_for_graphs.h
    └── steiner_tree_gain_computation_for_graphs.h
```
## References  
1. [Guide for Implementing a Custom Objective Function](https://github.com/kahypar/mt-kahypar/tree/master/mt-kahypar/partition/refinement/gains)