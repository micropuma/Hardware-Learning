#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include "Vtop.h"

int main(int argc, char** argv) {
  printf("Hello, ysyx!\n");

  VerilatedContext* const contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vtop* const top = new Vtop{contextp};

  while (!contextp->gotFinish()) {
    int a = rand() & 1;
    int b = rand() & 1;
    top->a = a;
    top->b = b;
    top->eval();
    printf("a = %d, b = %d, f = %d\n", a, b, top->f);
    assert(top->f == (a ^ b));
  }

  return 0;
}
