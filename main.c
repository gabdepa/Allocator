#include <stdio.h>
#include <stdlib.h>
#include "alocador.h"

int main(void)
{
    void *a, *b, *c, *d, *e, *f;

    iniciaAlocador();
    imprimeMapa();

    a = nextFit(100);
    imprimeMapa();
    
    b = nextFit(150);
    imprimeMapa();
    
    liberaMem(a);
    liberaMem(b);
    imprimeMapa();
    

    c = alocaMem(48);
    imprimeMapa();

    d = alocaMem(19);
    imprimeMapa();

    liberaMem(c);
    liberaMem(d);
    imprimeMapa();


    e = alocaMem(1);
    imprimeMapa();

    f = alocaMem(2);
    imprimeMapa();

    liberaMem(e);
    liberaMem(f);
    imprimeMapa();

    finalizaAlocador();
    return 1;
}