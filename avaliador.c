#include <stdio.h>
#include "alocador.h"

int main (long int argc, char** argv) {
  void *a,*b,*c,*d,*e;

  iniciaAlocador(); 
  // imprimeMapa();
  // 0) estado inicial

  a=(void *) firstFit(100);
  // imprimeMapa();
  b=(void *) firstFit(130);
  // imprimeMapa();
  c=(void *) firstFit(120);
  // imprimeMapa();
  d=(void *) firstFit(110);
  imprimeMapa();
  // 1) Espero ver quatro segmentos ocupados

  liberaMem(b);
  imprimeMapa(); 
  liberaMem(d);
  imprimeMapa(); 
  // 2) Espero ver quatro segmentos alternando
  //    ocupados e livres

  b=(void *) firstFit(50);
  imprimeMapa();
  d=(void *) firstFit(90);
  imprimeMapa();
  e=(void *) firstFit(40);
  imprimeMapa();
  // // 3) Deduzam
	
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
  //  // 4) volta ao estado inicial

  finalizaAlocador();
}