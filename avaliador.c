#include <stdio.h>
#include "alocador.h"

int main()
{
  void *a, *b, *c, *d, *e;

  // 0) Estado inicial
  iniciaAlocador();
  imprimeMapa();

  // 1) Espero ver quatro segmentos ocupados
  a = (void *)firstFit(100);
  // imprimeMapa();
  b = (void *)firstFit(130);
  // imprimeMapa();
  c = (void *)firstFit(120);
  // imprimeMapa();
  d = (void *)firstFit(110);
  imprimeMapa();

  // 2) Espero ver quatro segmentos alternando  ocupados e livres
  liberaMem(b);
  imprimeMapa();
  liberaMem(d);
  imprimeMapa();

  // 3) Deduzam
  b = (void *)firstFit(50);
  imprimeMapa();
  d = (void *)firstFit(90);
  imprimeMapa();
  e = (void *)firstFit(40);
  imprimeMapa();

  // 4) Volta ao estado inicial
  liberaMem(c);
  imprimeMapa();
  liberaMem(a);
  imprimeMapa();
  liberaMem(b);
  imprimeMapa();
  liberaMem(d);
  imprimeMapa();
  liberaMem(e);
  imprimeMapa();

  finalizaAlocador();
}