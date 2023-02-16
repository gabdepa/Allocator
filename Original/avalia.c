#include <stdio.h>
#include "meuAlocadorOrig.h"

int main (long int argc, char** argv) 
{
  void *a,*b,*c,*d,*e;

  iniciaAlocador(); 
  imprimeMapa();
  // 0) estado inicial
  // printf("\naloca a=100:\n");
  a=(void *) nextFit(100);
  imprimeMapa();
  // printf("\naloca b=130:\n");
  b=(void *) nextFit(130);
  imprimeMapa();
  // printf("\naloca c=120:\n");
  c=(void *) nextFit(120);
  imprimeMapa();
  // printf("\naloca d=110:\n");
  d=(void *) nextFit(110);
  imprimeMapa();

  // 1) Espero ver quatro segmentos ocupados
  // printf("\nlibera b->130:\n");
  liberaMem(b);
  imprimeMapa(); 

  // printf("\nlibera d->110:\n");
  liberaMem(d);
  imprimeMapa(); 
  // 2) Espero ver quatro segmentos alternando
  //    ocupados e livres

  // printf("\nAloca b=50:\n");
  b=(void *) nextFit(50);
  imprimeMapa();
  // printf("\nAloca d=90:\n");
  d=(void *) nextFit(90);
  imprimeMapa();
  // printf("\nAloca e=40:\n");
  e=(void *) nextFit(40);
  imprimeMapa();

  // 3) Deduzam
	
  // printf("\nlibera c->120:\n");
  liberaMem(c);
  imprimeMapa(); 
  // printf("\nlibera a->100:\n");
  liberaMem(a);
  imprimeMapa();
  // printf("\nlibera b->50:\n");
  liberaMem(b);
  imprimeMapa();
  // printf("\nlibera d->90:\n");
  liberaMem(d);
  imprimeMapa();
  // printf("\nlibera e->100:\n");
  liberaMem(e);
  imprimeMapa();
   // 4) volta ao estado inicial

  finalizaAlocador();
}
