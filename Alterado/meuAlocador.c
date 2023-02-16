#include <stdio.h>
#include <unistd.h>
#include <stdbool.h>

static void *topoInicialHeap; // Ponteiro para topo da Heap

void iniciaAlocador(void)
{
    printf("Init HEAP...\n");
    topoInicialHeap = sbrk(0);
}

void finalizaAlocador(void)
{
    brk(topoInicialHeap);
}

void *alocaMem(long int num_bytes)
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

    // Aloca o bloco de tam num_bytes no 'maior' e se sobrar espaço particiona o bloco para que ocorra posterior fusao//
    if (maior != topo && (maior[1] >= num_bytes + 16))
    {
        maior[0] = 1L;
        // Verifica se é possível particionar o bloco
        if (maior[1] >= num_bytes + 16)
        {
            long *novoBloco = (long *)((char *)maior + 16 + num_bytes);
            novoBloco[0] = 0L;
            novoBloco[1] = maior[1] - num_bytes - 16; // utiliza o restante da memoria nao utiliza para criar um novo bloco tal que consiga efetuar a fusao depois

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

    // Organiza os blocos
    long *prev = topoInicialHeap; // Pega o primeiro bloco da heap
    long *next = (long *)((char *)prev + 16 + prev[1]); // Pega o próximo bloco depois do inicial
    while (next != topo)
    {
        int flag = 0;
        while (prev[0] == 0L && next[0] == 0L && next != topo) // verifica se ambos estiverem livre e se o proximo nao eh o topo
        {
            // entao unifico blocos
            prev[1] = prev[1] + next[1] + 16; // Soma de tamanhos de prev e next
            next = (long *)((char *)prev + 16 + prev[1]); // bloco next adiciona tamanho do bloco prev
            flag = 1;  // Indica que ja foi unificado
        } 
        prev = next;  // Unifica blocos
        if (flag == 0)  // Caso não tenha conseguido unificar
            next = (long *)((char *)prev + 16 + prev[1]);  // bloco next adiciona tamanho do bloco prev
    }

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
            c = '+'; // bloco ocupado
        else
            c = '-'; // bloco livre
        for (int i = 0; i < count[1]; i++)
            putchar(c);
        
        count = (long *)((char *)count + 16 + count[1]); // Pega o próximo bloco, count[1] guarda o número de bytes que o bloco ocupa
    }

    putchar('\n');
    putchar('\n');
}
