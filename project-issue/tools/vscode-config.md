# vscode-config
> vscode的提供了诸多插件，这些插件对于项目的开发整个过程都提供了很多的帮助。  

## Cmake插件
cmake插件支持如下操作：  
* 项目的构建
* 项目的测试
* 项目的debug
* 代码检查，代码跳转，代码重构

其中，项目的构建依托`settings.json`文件，项目的debug依托`launch.json`。另一中项目构建的方式更加推荐，使用`CMakePreset.json`的方式，具体参考[cmake-presets](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html)原理文档以及vscode-cmake官方文档。

### JSON配置


## References
1. [vscode-doc](https://code.visualstudio.com/docs/editor/refactoring)
2. [vscode-cmake](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cmake-tools)