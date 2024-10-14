# TritonPart subproject  
## 引言
先前的VLSI hypergraph partition都只考虑了min-cut因素，而TritonPart将时序和资源异构纳入考量。**TritonPart**在如下三个方面相比先前的Sota有优势：  
1. 对于标准的min-cut划分，TritonPart相比[hMetis](http://ieeexplore.ieee.org/document/748202/)更有优势。
2. TritonPart是嵌入敏感的算法
3. TritonPart能够减少[关键路径](https://vlsi.kr/Slack/#:~:text=Definition%3A%20In%20a%20digital%20circuit,performance%20of%20the%20entire%20system.)被cut的数量，也能避免非关键路径变成关键路径。
4. TritonPart使用**多维度权重**，有flip-flops, LUTs, DSPs等多种资源。

## 基本原理

## TritonPart的工作流
![](../../png/workflow.png)

## 基准测试
论文中的基准测试，用Titan23 testbench，对比hMetis和KaHyPar这两个sota。

## References
1. [TritonPart论文](https://ieeexplore.ieee.org/abstract/document/10323975)
2. [OpenROAD talk](https://www.youtube.com/watch?v=z-yoZuJx2IE)
3. [OpenROAD 文档](https://openroad.readthedocs.io/en/latest/)