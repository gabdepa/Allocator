CC = gcc


SRCS = avaliador.c alocador.c 
HDRS = alocador.h

alocador.o: alocador.c $(HDRS)
	$(CC) -c alocador.c

avaliador.o: avaliador.c $(HDRS)
	$(CC) -c avaliador.c

avaliador: avaliador.o alocador.o
	$(CC)  avaliador.o alocador.o -o avaliador

clean:
	@ $(RM) *.o avaliador 

.PHONY: clean
