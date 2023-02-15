CC ?= gcc

OBJS := alocador.o
MAIN ?= avaliador
# -Wall -Wextra -Wpedantic
CFLAGS +=  -g

all: $(MAIN)

$(MAIN): $(MAIN).c $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

$(MAIN).c: ;

.c.o: 
	$(CC) -c $(CFLAGS) $< -o $@

clean:
	@ $(RM) *.o $(MAIN)

.PHONY: clean