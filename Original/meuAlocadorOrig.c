#include <stdio.h>
#include <unistd.h>
#include <stdbool.h>

static void *topoInicialHeap; // Ponteiro para topo da Heap
static long *prevAlloc;       // Ponteiro para Memória alocada anteriormente, utilizado no next fit

void iniciaAlocador(void)
{
    printf("Init HEAP...\n");
    topoInicialHeap = sbrk(0);
    prevAlloc = topoInicialHeap;
}

void finalizaAlocador(void)
{
    brk(topoInicialHeap); // Volta topo para topo incial da pilha, NULL
}

void *nextFit(long int num_bytes)
{
    long *topo = sbrk(0);   // Recupera Topo Atual da Pilha
    long *temp = prevAlloc; // Recebe Endereço da Alocação Anterior
    long retry = 0L;        // Quantidade de tentativas

    while (retry <= 1) // Percorre a lista de blocos 2 vezes
    {
        while (temp != topo)
        {
            if (temp[0] == 0L && temp[1] >= num_bytes) // Verifica se o bloco está livre e comporta o número necessário de bytes
            {
                temp[0] = 1L;                  // Indica que está ocupado
                if (temp[1] >= num_bytes + 16) // Verifica se é possível particionar o bloco
                {
                    long *novoBloco = (long *)((char *)temp + 16 + num_bytes); // Cria novo bloco da partição
                    novoBloco[0] = 0L;                                         // Indica como Livre
                    novoBloco[1] = temp[1] - num_bytes - 16;                   // Modifica tamanho

                    temp[1] = num_bytes; // Guarda tamanho do bloco
                }
                prevAlloc = (long *)((char *)temp + 16 + temp[1]); // Atualiza prevAlloc para última alocação
                return &temp[2];                                   // Retorna Endereço Alocado
            }
            temp = (long *)((char *)temp + 16 + temp[1]); // Pega próximo bloco da heap, temp[1] guarda tamanho do bloco
        }
        temp = topoInicialHeap; // Se não encontrou, percorre lista desde o começo
        ++retry;
    }

    // Caso não encontrou nenhum bloco na pilha:
    brk((char *)topo + 16 + num_bytes); // Sobe topo da pilha, acrescentando *topo
    topo[0] = 1L;                       // Sinaliza como ocupado
    topo[1] = num_bytes;                // Armazena tamanho de memória a ser alocado

    prevAlloc = (long *)((char *)topo + 16 + num_bytes); // Seta Alocação Anterior(PrevAlloc) para temp

    return &topo[2];
}

int liberaMem(void *block)
{
    long int *trata;

    trata = block;

    trata[-2] = 0; // Indica Bloco como livre

    block = NULL;

    return 1;
}

void imprimeMapa(void)
{
    long *count = topoInicialHeap; // Início da Pilha
    void *topoAtual = sbrk(0);     // Topo da Pilha
    char c;

    while (count != topoAtual)
    {
        printf("################"); // Cabeçalho do nó
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
