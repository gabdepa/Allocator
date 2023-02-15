#ifndef __ALOCADOR__
#define __ALOCADOR__

// #define INCREMENT 4096
// #define HEADER_SIZE 16
// void *topoInicialHeap;
// void *topoBlocos;
// static long *prevAlloc;

/**
 * @brief Inicialização do Alocador
 *
 * Executa a syscall brk para obter o o endereço do topo corrente da heap e o
 * coloca na variável global "topoInicialHeap"
 */
void iniciaAlocador(void);

/**
 * @brief Finaliza alocador
 *
 * Executa syscall brk para restaurar o valor original da heap contido
 * na variável "topoInicialHeap"
 */
void finalizaAlocador(void);

/**
 * @brief Desaloca o bloco de memória
 *
 * Indica se o bloco foi liberado ou não
 * @param block bloco  de memória a ser liberado
 * @return "1": Sucesso e "0": Falha
 */
int liberaMem(void *block);

/**
 * @brief Imprime um mapa de memória da Heap
 *
 * Cada byte da parte gerencial do nó deve ser impresso
 * com o caracter "#". O caracter usado para
 * a impressão dos bytes do bloco de cada nó depende
 * se o bloco estiver livre ou ocupado. Se estiver livre, imprime o
 * caractere "-". Se estiver ocupado, imprime o caractere "+".
 */
void printMapa(void);

/**
 * @brief Implementa o Next Fit, alocando um bloco de "num_bytes"
 * 
 * 1)Procura um bloco livre com tamanho maior ou igual a "num_bytes"
 * 2)Se encontrar, indica que o bloco está ocupado e retorna o endereço inicial do bloco
 * 3)Se não encontrar, abre espaço para um novo bloco usando a syscall brk, indica que o bloco está ocupado e retorna o endereço inicial do bloco.
 * @param num_bytes Quantidade de bytes a ser alocado
 * @return Endereço do novo bloco alocado 
*/
void *nextFit(int num_bytes);

/**
 * @brief Implementa o First Fit, alocando um bloco de "num_bytes"
 * 
 * 1. Procura um bloco livre com tamanho maior ou igual a `num_bytes`
 * 2. Se encontrar, indica que o bloco está ocupado e retorna o endereço inicial do bloco
 * 3. Se não encontrar, abre espaço para um novo bloco usando a syscall brk, indica que o bloco está ocupado e retorna o endereço inicial o bloco.
 * @param num_bytes Quantidade de bytes a ser alocado
 * @return Endereço do novo bloco alocado 
*/
void *firstFit(int num_bytes);







void *bestFit(long int num_bytes);
#endif