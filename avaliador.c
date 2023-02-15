#include <stdio.h>
#include <unistd.h>
#include <stdbool.h>
#include "alocador.h"

int main()
{
  void *a, *b, *c, *d, *e;

  // 0) Estado inicial
  iniciaAlocador();
  printMapa();

  // First Fit
  printf("FIRST FIT:\n");
  a = (void *)firstFit(100);
  b = (void *)firstFit(130);
  c = (void *)firstFit(120);
  d = (void *)firstFit(110);
  printMapa();

  // Vizualiação da Heap
  liberaMem(b);
  printMapa();
  liberaMem(d);
  printMapa();

  // Next Fit
  printf("NEXT FIT:\n");
  b = (void *)nextFit(50);
  d = (void *)nextFit(90);
  e = (void *)nextFit(40);
  printMapa();

  // Voltando ao Estado inicial
  liberaMem(c);
  printMapa();
  liberaMem(a);
  printMapa();
  liberaMem(b);
  printMapa();
  liberaMem(d);
  printMapa();
  liberaMem(e);
  printMapa();

  finalizaAlocador();
}