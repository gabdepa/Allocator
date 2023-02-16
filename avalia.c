#include <stdio.h>
#include "meuAlocador.h"

int main (long int argc, char** argv) {
  void *a,*b,*c,*d,*e;

  iniciaAlocador(); 
  imprimeMapa();
  // 0) estado inicial

  a=(void *) nextFit(100);
  imprimeMapa();
  b=(void *) nextFit(130);
  imprimeMapa();
  c=(void *) nextFit(120);
  imprimeMapa();
  d=(void *) nextFit(110);
  imprimeMapa();
  // 1) Espero ver quatro segmentos ocupados
  printf("Espero ver quatro segmentos ocupados\n");
  liberaMem(b);
  imprimeMapa(); 
  liberaMem(d);
  imprimeMapa(); 
  // 2) Espero ver quatro segmentos alternando
  //    ocupados e livres

  b=(void *) nextFit(50);
  imprimeMapa();
  d=(void *) nextFit(90);
  imprimeMapa();
  e=(void *) nextFit(40);
  imprimeMapa();
  // 3) Deduzam
	
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
   // 4) volta ao estado inicial

  finalizaAlocador();
}
