#include <stdio.h>
#include <unistd.h>
#include <stdbool.h>
#include "alocador.h"

int main()
{
  void *a_ff, *b_ff, *c_ff; // ponteiros para alocação First Fit
  void *d_nf, *e_nf, *f_nf; // ponteiros para alocação Next Fit
  void *g_al, *h_al, *i_al; // ponteiros para alocação Alocador V2
  void *j_bf, *k_bf, *l_bf; // ponteiros para alocação Best Fit

  // Estado inicial
  iniciaAlocador();
  printf("Estado Inicial:\n");
  imprimeMapa();

  // First Fit
  printf("FIRST FIT:\n");
  a_ff = (void *)firstFit(50);
  imprimeMapa();
  b_ff = (void *)firstFit(90);
  imprimeMapa();
  c_ff = (void *)firstFit(40);
  imprimeMapa();

  // Next Fit
  printf("NEXT FIT:\n");
  d_nf = (void *)nextFit(50);
  imprimeMapa();
  e_nf = (void *)nextFit(90);
  imprimeMapa();
  f_nf = (void *)nextFit(40);
  imprimeMapa();

  // Alocador V2
  printf("ALOCADOR V2:\n");
  g_al = (void *)alocadorV2(50);
  imprimeMapa();
  h_al = (void *)alocadorV2(90);
  imprimeMapa();
  i_al = (void *)alocadorV2(40);
  imprimeMapa();

  // Best Fit
  printf("BEST FIT:\n");
  j_bf = (void *)bestFit(50);
  imprimeMapa();
  k_bf = (void *)bestFit(90);
  imprimeMapa();
  l_bf = (void *)bestFit(40);
  imprimeMapa();

  // Voltando ao Estado inicial
  // Liberando Best Fit
  printf("Liberando Best Fit...\n");
  liberaMem(l_bf);
  liberaMem(k_bf);
  liberaMem(j_bf);
  imprimeMapa();

  // Liberando Alocador V2
  printf("Liberando Alocador V2...\n");
  liberaMem(i_al);
  liberaMem(h_al);
  liberaMem(g_al);
  imprimeMapa();

  // Liberando Next Fit
  printf("Liberando Next Fit...\n");
  liberaMem(f_nf);
  liberaMem(e_nf);
  liberaMem(d_nf);
  imprimeMapa();

  // Liberando First Fit
  printf("Liberando First Fit...\n");
  liberaMem(c_ff);
  liberaMem(b_ff);
  liberaMem(a_ff);
  imprimeMapa();

  printf("\nEstado Final:\n");
  finalizaAlocador();
  imprimeMapa();  
  return 0;
}