#include <stdio.h>
#include <unistd.h>
#include <stdbool.h>

static void *topoInicialHeap; // Ponteiro para Topo Inicial da Heap
static void *topoAtual; // Ponteiro para Topo Atual da Heap
static void *prevAlloc; // Ponteiro para Alocação anterior

void iniciaAlocador(void)
{
    printf("Init HEAP...\n");
    topoInicialHeap = sbrk(0);       
    prevAlloc = topoInicialHeap; 
    topoAtual = sbrk(0);        
}

void finalizaAlocador(void)
{
    topoAtual = topoInicialHeap; // Topo Atual recebe o valor inicial da Heap, 0
    brk(topoInicialHeap); // Retorna topo da heap ao seu valor Inicial 
}

void *bestFit(long int num_bytes)
{
    long *temp = topoInicialHeap;
    long *menor = temp;

    // Percorre a Heap
    while (temp != topoAtual)
    {
        if (temp[0] == 0) // bloco está livre
        {
            if ((temp[1] >= num_bytes) && (temp[1] < menor[1])) // menor bloco que é maior do que o solicitado
            {
                menor = temp;
            }
        }
        temp = (long *)((char *)temp + 16 + temp[1]); // Pega o próximo bloco, temp[1] guarda o número de bytes que o bloco ocupa
    }

    // Caso o menor ainda seja igual o valor inicial, não existe um bloco q se encaixe nos parâmetros, Falha
    if (menor == topoInicialHeap)
    {
        int valorsbrk;        // Variável usada para alocar memória na heap
        void *topo = sbrk(0); /// Guarda valor do topo atual para ser usado em aritmética, pode diferenciar de topoAtual
        // Aloca memória a mais necessária
        if ((topo + 16 + num_bytes) > topoAtual)
        {
            int alocaTrue = (topo + 16 + num_bytes) - topoAtual; // Verifica diferença dos topos
            valorsbrk = ((alocaTrue / 4096) + 1) * 4096;     // Cria novo bloco múltiplo de 4096
            sbrk(valorsbrk);                                     // Aloca novo espaço na heap
        }

        // Sinaliza como ocupado e armazena tam de memória a ser alocado
        long int *endereço;
        endereço[0] = 1;           // Sinaliza como ocupado (tamanho = 8bytes)
        endereço[1] = num_bytes;    // Armazena tam de memória alocado (tamanho = 8bytes)
        prevAlloc = endereço;       // Atualiza prevAlloc para última alocação
        topoAtual = brk(valorsbrk); // Atualiza topoAtual para o final da Heap

        return ((char *)&endereço[2]); // Retorna ponteiro para endereço
    }
    else // Encontrei um bloco que se encaixe nos parâmetros, Successo
    {
        menor[0] = 1;               // marca bloco como ocupado
        menor[1] = num_bytes;       // guarda tamanho da alocação(num_bytes) na posição 1
        prevAlloc = menor;          // Atualiza prevAlloc para última alocação
        return ((char *)&menor[2]); // Retorna ponteiro para endereço
    }
}

void *firstFit(int num_bytes)
{
    long *temp = topoInicialHeap;

    // Percorre a Heap procurando o primeiro bloco livre
    while (temp != topoAtual)
    {
        if ((temp[0] == 0) && (temp[1] >= num_bytes)) // bloco está livre & comporta o número desejado
        {
            temp[0] = 1;               // marca bloco como ocupado
            temp[1] = num_bytes;       // guarda tamanho da alocação(num_bytes) na posição 1
            return ((char *)&temp[2]); // Retorna ponteiro para endereço
        }
        temp = (long *)((char *)temp + 16 + temp[1]); // Pega o próximo bloco, temp[1] guarda o número de bytes que o bloco ocupa
    }

    int valorsbrk;        // Variável usada para alocar memória na heap
    void *topo = sbrk(0); /// Guarda valor do topo atual para ser usado em aritmética, pode diferenciar de topoAtual
    // Aloca memória a mais necessária
    if ((topo + 16 + num_bytes) > topoAtual)
    {
        int alocaTrue = (topo + 16 + num_bytes) - topoAtual; // Verifica diferença dos topos
        valorsbrk = ((alocaTrue / 4096) + 1) * 4096;     // Cria novo bloco múltiplo de 4096
        sbrk(valorsbrk);                                     // Aloca novo espaço na heap
    }

    // Sinaliza como ocupado e armazena tam de memória a ser alocado
    void *endereço;
    endereço[0] = 1L;           // Sinaliza como ocupado (tamanho = 8bytes)
    endereço[1] = num_bytes;    // Armazena tam de memória alocado (tamanho = 8bytes)
    prevAlloc = endereço;       // Atualiza prevAlloc para última alocação
    topoAtual = brk(valorsbrk); // Atualiza topoAtual para o final da Heap

    return ((char *)&endereço[2]); // Retorna ponteiro para endereço
}

void *nextFit(int num_bytes)
{
    long *temp = prevAlloc;

    // Percorre a lista de blocos 2 vezes
    for (int retry = 0; retry < 2; retry++)
    {
        while (temp != topoAtual) // Enquanto o topo anterior for diferente do topo Atual
        {
            if (temp[0] == 0 && temp[1] >= num_bytes)
            {
                // Verifica se é possível particionar o bloco
                if (temp[1] >= num_bytes + 16)
                {
                    long *novoBloco = (long *)((char *)temp + 16 + num_bytes); // Cria novo bloco da partição
                    novoBloco[0] = 0L;                                         // Indica como Livre
                    novoBloco[1] = temp[1] - (num_bytes + 16);                 // Modifica tamanho
                    temp[1] = num_bytes;                                       // Guarda o tamanho do bloco depois de particionado
                    prevAlloc = (long *)((char *)temp + 16 + temp[1]);         // Atualiza PrevAlloc
                    return &temp[2];
                }
                temp[0] = 1;               // marca bloco como ocupado
                temp[1] = num_bytes;       // guarda tamanho da alocação(num_bytes) na posição 1
                return ((char *)&temp[2]); // Retorna ponteiro para endereço
            }
            temp = (long *)((char *)temp + 16 + temp[1]); // Pega o próximo bloco, temp[1] guarda o número de bytes que o bloco ocupa
        }
        temp = topoInicialHeap; // Percorre a lista do começo
    }

    int valorsbrk;        // Variável usada para alocar memória na heap
    void *topo = sbrk(0); /// Guarda valor do topo atual para ser usado em aritmética, pode diferenciar de topoAtual
    // Aloca memória a mais necessária
    if ((topo + 16 + num_bytes) > topoAtual)
    {
        int alocaTrue = (topo + 16 + num_bytes) - topoAtual; // Verifica diferença dos topos
        valorsbrk = ((alocaTrue / 4096) + 1) * 4096;     // Cria novo bloco múltiplo de 4096
        sbrk(valorsbrk);                                     // Aloca novo espaço na heap
    }

    // Sinaliza como ocupado e armazena tam de memória a ser alocado
    void *endereço;
    endereço[0] = 1L;           // Sinaliza como ocupado (tamanho = 8bytes)
    endereço[1] = num_bytes;    // Armazena tam de memória alocado (tamanho = 8bytes)
    prevAlloc = endereço;       // Atualiza prevAlloc para última alocação
    topoAtual = brk(valorsbrk); // Atualiza topoAtual para o final da Heap

    return ((char *)&endereço[2]); // Retorna ponteiro para endereço
}

int liberaMem(void *block)
{
    long *temp = block;
    int ret = 0;

    if (temp[-2] == 1) // Bloco está Ocupado
    {
        temp[-2] = 0; // Indica bloco como livre
        temp = NULL; // Zera o bloco
        ret = 1;
    }

    // Organiza os blocos
    long *prev = topoInicialHeap; // Pega o primeiro bloco da heap
    long *next = (long *)((char *)prev + 16 + prev[1]); // Pega o próximo bloco depois do inicial
    while (next != topoAtual)
    {
        int flag = 0;
        while ((prev[0] == 0) && (next[0] == 0) && (next != topoAtual))
        {
            prev[1] = prev[1] + next[1] + 16;             // Soma de tamanhos de prev e next
            next = (long *)((char *)prev + 16 + prev[1]); // bloco next adiciona tamanho do bloco prev
            flag = 1; // Indica que ja foi unificado
        }
        prev = next; // Unifica blocos
        if (flag == 0) // Caso ainda não tenha unificado
            next = (long *)((char *)prev + 16 + prev[1]); // bloco next adiciona tamanho do bloco prev
    }

    return ret;
}

void printMapa(void)
{
    long *count = topoInicialHeap;
    void *topo = topoAtual;
    char c;

    while (count != topo)
    {
        if (count[0] == 1)
            c = '+'; // bloco está ocupado
        else
            c = '-'; // bloco está livre
        for (int i = 0; i < count[1]; i++)// percorre tamanho do bloco
            putchar(c); 

        count = (long *)((char *)count + 16 + count[1]); // Pega o próximo bloco, count[1] guarda o número de bytes que o bloco ocupa
    }

    putchar('\n');
    putchar('\n');
}
