# Cmake tips and issues
## Classic vs. new Cmake 
refer to [cmake guide](https://cliutils.gitlab.io/modern-cmake/chapters/intro/running.html)
```shell
~/package $ mkdir build
~/package $ cd build
~/package/build $ cmake ..
~/package/build $ make
```
the shell script above is classical ones.
```shell
~/package $ cmake -S . -B build
~/package $ cmake --build build
```
the shell above is new one.

