#include <stdio.h>
#include <unistd.h>
#include <stdbool.h>

static void *topoInicialHeap; // Ponteiro para topo da Heap
static long *prevAlloc;       // Ponteiro para Memória alocada anteriormente, utilizado no next fit

#define INCREMENT 4096
#define HEADER_SIZE 16

void iniciaAlocador(void)
{
    printf("Init HEAP...\n");
    prevAlloc = topoInicialHeap = sbrk(0);
}

void finalizaAlocador(void)
{
    brk(topoInicialHeap);
}

void *alocaMem(long int num_bytes)
{
    long *topo = sbrk(0);
    long *temp = prevAlloc;
    long retry = 0L;

    // Percorre a lista de blocos 2 vezes
    while (retry <= 1)
    {
        while (temp != topo)
        {
            if (temp[0] == 0L && temp[1] >= num_bytes)
            {
                temp[0] = 1L;

                // Verifica se é possível particionar o bloco
                if (temp[1] >= num_bytes + 16)
                {
                    long *novoBloco = (long *)((char *)temp + 16 + num_bytes);
                    novoBloco[0] = 0L;
                    novoBloco[1] = temp[1] - num_bytes - 16;

                    temp[1] = num_bytes;
                }
                prevAlloc = (long *)((char *)temp + 16 + temp[1]);
                return &temp[2];
            }
            temp = (long *)((char *)temp + 16 + temp[1]);
        }
        temp = topoInicialHeap;
        ++retry;
    }

    // Sinaliza como ocupado e armazena tam de memória a ser alocado
    brk((char *)topo + 16 + num_bytes);
    topo[0] = 1L;
    topo[1] = num_bytes;

    prevAlloc = (long *)((char *)topo + 16 + num_bytes);

    return &topo[2];
}

int liberaMem(void *block)
{
    long *topo = sbrk(0);
    long *temp = block;
    int ret = 0;

    if (temp[-2] == 1L) // Se está ocupado
    {
        temp[-2] = 0L; // Seta para livre
        ret = 1;
    }

    long *prev = topoInicialHeap;
    long *next = (long *)((char *)prev + 16 + prev[1]);
    while (next != topo)
    {
        int flag = 0;
        while (prev[0] == 0L && next[0] == 0L && next != topo)
        {
            prev[1] = prev[1] + next[1] + 16;
            next = (long *)((char *)prev + 16 + prev[1]);
            flag = 1;
        }
        prev = next;
        if (flag == 0)
            next = (long *)((char *)prev + 16 + prev[1]);
    }

    // prevAlloc = (long *)(temp[-1] + (char *)temp);
    return ret;
}

void imprimeMapa(void)
{
    long *count = topoInicialHeap;
    void *topoAtual = sbrk(0);
    char c;

    while (count != topoAtual)
    {
        printf("################");
        if (count[0] == 1)
            c = '+'; // ocupado
        else
            c = '-'; // livre
        for (int i = 0; i < count[1]; i++)
            putchar(c);

        count = (long *)((char *)count + 16 + count[1]);
    }

    putchar('\n');
    putchar('\n');
}
