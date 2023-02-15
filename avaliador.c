#include <stdio.h>
#include <unistd.h>
#include <stdbool.h>
#include "alocador.h"

int main()
{
  void *a_ff, *b_ff, *c_ff; // ponteiros para alocação First Fit
  void *d_nf, *e_nf, *f_nf; // ponteiros para alocação Next Fit
  void *g_bf, *h_bf, *i_bf; // ponteiros para alocação Best Fit
  void *j_al, *k_al, *l_al; // ponteiros para alocação Best Fit

  // Estado inicial
  printf("Estado Inicial:\n");
  iniciaAlocador();
  printMapa();

  // First Fit
  printf("FIRST FIT:\n");
  a_ff = (void *)firstFit(50);
  printMapa();
  b_ff = (void *)firstFit(90);
  printMapa();
  c_ff = (void *)firstFit(40);
  printMapa();

  // Next Fit
  printf("NEXT FIT:\n");
  d_nf = (void *)nextFit(50);
  printMapa();
  e_nf = (void *)nextFit(90);
  printMapa();
  f_nf = (void *)nextFit(40);
  printMapa();

  // Alocador V2
  printf("ALOCADOR V2:\n");
  j_al = (void *)alocadorV2(50);
  printMapa();
  k_al = (void *)alocadorV2(90);
  printMapa();
  l_al = (void *)alocadorV2(40);
  printMapa();

  // Best Fit
  printf("BEST FIT:\n");
  g_bf = (void *)bestFit(50);
  printMapa();
  h_bf = (void *)bestFit(90);
  printMapa();
  i_bf = (void *)bestFit(40);
  printMapa();

  // Voltando ao Estado inicial
  liberaMem(a_ff);

  liberaMem(b_ff);

  liberaMem(c_ff);

  liberaMem(d_nf);

  liberaMem(e_nf);

  liberaMem(f_nf);

  liberaMem(g_bf);

  liberaMem(h_bf);

  liberaMem(i_bf);

  liberaMem(j_al);

  liberaMem(k_al);

  liberaMem(l_al);

  printf("Estado Final:\n");
  printMapa();

  finalizaAlocador();
  return 0;
}