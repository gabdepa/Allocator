#include <stdio.h>
#include <unistd.h>
#include <stdbool.h>


static void *topoInicialHeap; // Ponteiro para topo da Heap
static long *prevAlloc;       // Memória alocada anteriormente, utilizado no next fit
void *topoBlocos;             // Cabeçalho dos Blocos

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

void *bestFit(long int num_bytes)
{
    // Retorna NULL caso entrada seja inválida
    if (num_bytes <= 0)
        return NULL;

    long int bestFit = 0;
    long int *cabecalho;
    void *iterator = topoInicialHeap;
    void *comecoBloco = topoBlocos;
    long int *isDisp;
    long int disp;
    long int mult;
    long int excesso;
    long int *bloco;

    sbrk(24);

    // Procura bloco livre para ser alocado
    while (iterator < topoBlocos)
    {
        cabecalho = iterator;
        if (!cabecalho[0] && (cabecalho[1] >= num_bytes) && ((cabecalho[1] < bestFit) || !bestFit))
        {
            bestFit = cabecalho[1];
            comecoBloco = iterator;
        }
        iterator += 16 + cabecalho[1];
    }

    // Retorna caso algum bloco livre foi achado
    if (bestFit)
    {
        isDisp = comecoBloco;
        *isDisp = 1;
        return comecoBloco + 16;
    }

    // Aloca quanta memória a mais for necessária
    disp = sbrk(0) - topoBlocos;
    if (16 + num_bytes > disp)
    {
        excesso = 16 + num_bytes - disp;
        mult = 1 + ((excesso - 1) / 4096); // utiliza blocos de 4096 bytes, especificação 6.2c
        sbrk(4096 * mult);                 // aloca bloco de tamanho 4096*n
    }

    // Insere cabeçalho do bloco
    bloco = topoBlocos;
    bloco[0] = 1;
    bloco[1] = num_bytes;

    // Atualiza variável topoBlocos
    topoBlocos += 16 + num_bytes;

    return (void *)bloco + 16;
}

void *firstFit(int num_bytes)
{
    long *topo = sbrk(0);
    long *temp = topoInicialHeap;
    long *maior = temp;

    // seleciona primeiro bloco livre como maior
    while (temp != topo && (maior[0] == 1 && temp[0] == 1))
        temp = (long *)((char *)temp + 16 + temp[1]);
    maior = temp;

    // itera a heap em busca do maior bloco (até o fim)
    while (temp != topo)
    {
        if (temp[0] == 0L && temp[1] > maior[1])
            maior = temp;
        temp = (long *)((char *)temp + 16 + temp[1]);
    }

    // aloca o bloco de tam num_bytes no 'maior' e se sobrar espaço particiona o bloco //
    if (maior != topo && (maior[1] >= num_bytes + 16))
    {
        maior[0] = 1L;
        // verifica se é possível particionar o bloco
        if (maior[1] >= num_bytes + 16)
        {
            long *novoBloco = (long *)((char *)maior + 16 + num_bytes);
            novoBloco[0] = 0L;
            novoBloco[1] = maior[1] - num_bytes - 16;

            maior[1] = num_bytes;
        }
        return &maior[2];
    }

    // sinaliza como ocupado e armazena tam de memória a ser alocado
    brk((char *)topo + 16 + num_bytes);
    topo[0] = 1L;
    topo[1] = num_bytes;

    return &topo[2];
}

void *nextFit(int num_bytes)
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

                // verifica se é possível particionar o bloco
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

    // sinaliza como ocupado e armazena tam de memória a ser alocado
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

    if (temp[-2] == 1L)
    {
        temp[-2] = 0L;
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

    prevAlloc = (long *)(temp[-1] + (char *)temp);
    return ret;
}

void printMapa(void)
{
    long *count = topoInicialHeap;
    void *topoAtual = sbrk(0);
    char c;

    while (count != topoAtual)
    {
        printf("################");
        if (count[0] == 1)
            c = '*'; // ocupado
        else
            c = '~'; //livre
        for (int i = 0; i < count[1]; i++)
            putchar(c);

        count = (long *)((char *)count + 16 + count[1]);
    }

    putchar('\n');
    putchar('\n');
}
