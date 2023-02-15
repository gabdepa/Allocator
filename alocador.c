#include <stdio.h>
#include <unistd.h>
#include <stdbool.h>

static void *topoInicialHeap; // Ponteiro para topo da Heap
static long *prevAlloc;       // Memória alocada anteriormente, utilizado no next fit

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
    long int *bestfit = NULL;
    long int bftam = 0xffffff;
    long int *a = topoInicialHeap;
    void *topoAtual = sbrk(0);

    while (a != topoAtual)
    {
        if (a[0] == 0)
        {
            if (a[1] >= num_bytes)
            {
                if (a[1] < bftam)
                {
                    bftam = a[1];
                    bestfit = a;
                }
            }
        }
        a += 2 + (a[1] / 8);
    }

   if(topoInicialHeap + num_bytes > topoAtual)
   {
        int alocaTrue = topoAtual - topoInicialHeap;
        alocaTrue = num_bytes - alocaTrue;
        int valorsbrk = ((alocaTrue/4096) + 1)*4096;
        sbrk(valorsbrk);
        sbrk(0);
    }

    if (!bestfit)
    {
        long int *info;
        // abre 8 bytes para um long que indica se o bloco esta ocupado
        info = sbrk(0);
        info[0] = 1;
        // abre outros 8 bytes para guardar o tamanho do bloco
        info[1] = num_bytes;
        // aloca o espaco necessario do bloco
        void *endereco = &info[2];
        topoHeapHeap += num_bytes + (2*8);
        return ((char *)endereco);
    }
    else
    {
        bestfit[0] = 1;
        bestfit[1] = bftam;
        // bestfit + 16 bytes
        return ((char *)&bestfit[2]);
    }
}

void *firstFit(long int num_bytes)
{
    long *topo = sbrk(0);
    long *temp = topoInicialHeap;
    long *maior = temp;

    // Seleciona primeiro bloco livre como maior
    while (temp != topo && (maior[0] == 1 && temp[0] == 1))
        temp = (long *)((char *)temp + 16 + temp[1]);
    maior = temp;

    // Itera a heap em busca do maior bloco até o fim
    while (temp != topo)
    {
        if (temp[0] == 0L && temp[1] > maior[1])
            maior = temp;
        temp = (long *)((char *)temp + 16 + temp[1]);
    }

    // Aloca o bloco de tam num_bytes no 'maior' e se sobrar espaço particiona o bloco //
    if (maior != topo && (maior[1] >= num_bytes + 16))
    {
        maior[0] = 1L;
        // Verifica se é possível particionar o bloco
        if (maior[1] >= num_bytes + 16)
        {
            long *novoBloco = (long *)((char *)maior + 16 + num_bytes);
            novoBloco[0] = 0L;
            novoBloco[1] = maior[1] - num_bytes - 16;

            maior[1] = num_bytes;
        }
        return &maior[2];
    }

    // Sinaliza como ocupado e armazena tam de memória a ser alocado
    brk((char *)topo + 16 + num_bytes);
    topo[0] = 1L;
    topo[1] = num_bytes;

    return &topo[2];
}

void *nextFit(long int num_bytes)
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
