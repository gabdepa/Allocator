.section .data
    topoInicialHeap:    .quad 0
    topoAtualHeap:      .quad 0
    tamAloc:            .quad 0
    blockSize:          .quad 4096

    tamanhoBestFit:     .quad 0xffffffff
    enderecoBestFit:    .quad 0
    
    str_init:           .string "Init printf() heap arena\n"
    str_cabc:           .string "################"
    plus_char:          .byte 43
    minus_char:         .byte 45

    prevAlloc:          .quad 0 # Utilizado no nextFit  e bestFit
   
.globl topoInicialHeap
.globl prevAlloc  

.section .text

.globl iniciaAlocador
iniciaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    # Inicializa buffer do printf() alocado na heap
    movq $0, %rax              # parâmetros variádicos printf (nulo)
    movq $str_init, %rdi       # primeiro parâmetro printf
    call printf

    # Obtem topo inicial da heap
    movq $0, %rdi              # primeiro parâmetro brk
    movq $12, %rax             # No de syscall do brk
    syscall                    # brk(0)
    movq %rax, topoInicialHeap # topo da heap (retorno de brk)
    movq %rax, prevAlloc       # prevAlloc := topoInicialHeap

    popq %rbp

    ret

.globl finalizaAlocador
finalizaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    movq topoInicialHeap, %rdi # primeiro parâmetro brk
    movq $12, %rax             # No de syscall do brk
    syscall
    movq %rax, topoInicialHeap # topo da heap (retorno de brk)

    popq %rbp

    ret

.globl bestFit
bestFit:

    pushq %rbp
    movq  %rsp, %rbp

    mov  %rdi           , tamAloc         # salva o tamanho da alocacao
    mov  topoInicialHeap, %r12            # Salva o topo da heap em r12
    movq $0, enderecoBestFit              # enderecoBestFit = NULL


    movq prevAlloc, %rbx

    w0: 
        cmpq %r12 , prevAlloc           # compara o topo inicial com o topo atual já alocado
        je fim_w0
        
        mov %r12     , %r14               # salva o endereco inicial 

        mov (%r12), %r15                  # bloco de "livre ou não"  -> r15, a[0] == 0
        cmp $0    , %r15                  # se ocupado, procura proximo bloco 
        jne prox_bloc_1                   # pula para o próximo bloco

        add $8       , %r12               # vai para o espaço do tamanho
        mov (%r12)   , %r15               # salva o tamanho em r15
        cmpq tamAloc , %r15               # compara se o espaço disponivel é suficiente, a[1] >= num_bytes
        jl  prox_bloc_2                   # pula para o próximo bloco

        cmp tamanhoBestFit, %r15          # comparo para ver se o tamanho atual é o ideal
        jge prox_bloc_2                   # se nao for, procuro o proximo bloco

        movq %r14, enderecoBestFit        # salva o endereço do bloco ideal, bestfit = a;
        movq %r15, tamanhoBestFit         # salva o tamanho  do bloco ideal, bftam = a[1];
        
        jmp prox_bloc_2                   # pula para o proximo bloco

        prox_bloc_1:                      # aqui o loop morreu lgo no começo
        add $8       , %r12               #  entao é preciso add 8 agora e mais 8
        mov (%r12)   , %r15               #  daqui a pouco pra fechar o cabeçalho

        prox_bloc_2:                      # aqui é se só nao tem tamanho o suficiente
        add $8       , %r12               # soma os 8 restantes
        add %r15     , %r12               # e soma o tamanho do bloco que foi analizado

        jmp w0                            # volta para o inicio do loop

    fim_w0:

    mov $0  , %r13                        # move 0 para r13
    cmp %r13, enderecoBestFit             # compara o enderecoBestFit com, 0 *bestfit == NULL
    je inicio_alocacao                    # se forem iguais, inicia uma nova alocação
                                          # senão, usa o endereco salvo em enderecoBestFit

    # Achou o melhor lugar para armazenar os novos dados sem a necessidade de uma nova alocação

    movq enderecoBestFit, %r12        # salva o endereço ideal em r12

    mov $1      ,  %r13               # marca o bloco como indisponivel ,   bestfit[0] = 1;
    mov %r13    , (%r12)              # bestfit[1] = bftam;
    add $16     ,  %r12               # como nao podemos mudar o tamanho do bloco, pula 16 bytes

    mov %r12    , %rax                # salva r12 no registrador de retorno 



    jmp fim_aloc                      # pula para o fim da alocação

    inicio_alocacao:
    # Não tinha um espaço disponivel, confere se pode botar no final do espaço já alocado

    # se ((num_bytes + 16) > (topoAtual(sbrk(0)) - prevAlloc)) -> aloca
    # senão, bota ali mesmo e atualiza o valor de prevAlloc
    mov  $12, %rax               # codigo referente ao brk
    mov  $0 , %rdi               # 0 para retornar o topo da heap
    syscall                      # executa a sycall
    movq %rax, topoAtualHeap     # retorno em %rax e salvo em topoAtualHeap

    # alocaTrue = topoBloco - prevAlloc
    movq topoAtualHeap, %rax     # salva o topo atual em rax
    subq prevAlloc  , %rax       # diminuiu o topo alocado de rax para termos o tamanho total disponivel

    movq tamAloc      , %rbx     # move o tamanho da alocação atual para rbx 
    add  $16          , %rbx     # adiciona os 16 bytes de cabeçalho

    cmp %rax          , %rbx     # ve se tem espaço disponivel sem a necessidade de fazer uma nova alocação de tamanho = blockSize
    jle nao_aloca_4096           # se não, não pula para alocação

                                 # foi necessária a alocação
    movq %rbx  , %r12            # joga o tamanho que eu quero alocar em r12, alocaTrue = num_bytes - alocaTrue
    subq %rax  , %r12            # diminui o resto do espaço que ainda tem disponivel

    mov %r12   , %rax            # salva o espaço que vai ser alocado em rax          

    movq blockSize, %r12         # move o tamanho do bloco para r12
    mov $0        , %rdx         # acho que precisa para funcionar a divisão 
    idivq %r12                   # divide o tamanho da alocação por blocksize (rax = rax / 4096)
    mov $0, %r13                 # bota zero em r13
    cmp %rdx, %r13               # ve se o resto da divisão é zero
    je nao_soma                  # se for, nao precisa somar 1 no quociente
    add $1, %rax                 # soma 1 porque a divisão é apenas de inteiros
    nao_soma:
    mulq %r12                    # multiplica o resultado por blockSize para saber quantos bytes alocar, a partir do número de blocos 
    movq topoAtualHeap, %rdi     # salva o topo atual em rdi
    add  %rax         , %rdi     # adiciona o tamanho da alocação atual
    mov $12, %rax                #
    syscall                      # chama a syscall de alocação

    nao_aloca_4096:
    movq prevAlloc,  %r12        # salva o endereço do prevAlloc em r12
    movq $1         ,  %r13      # info[0] = 1
    mov %r13        , (%r12)     # informa que o bloco está alocado
    add $8          ,  %r12      # abre 8 bytes para um long que indica se o bloco esta ocupado
    movq tamAloc    ,  %r13      # info[1] = num_bytes
    mov %r13        , (%r12)     # informa o tamanho do bloco alocado
    add $8          ,  %r12      # abre outros 8 bytes para guardar o tamanho do bloco
    mov %r12        , %rax       # Envia o endereço para reg de retorno
    addq tamAloc    , %r12
    movq %r12, prevAlloc         # Atualiza o valor do prevAlloc,  prevAlloc += num_bytes + (2 * 8);

    fim_aloc:
    popq %rbp

ret


.globl nextFit
nextFit:
    pushq %rbp
    movq %rsp, %rbp

    # -8(%rbp) := topo ; -16(%rbp) := temp ;
    # -24(%rbp) := retry ;
    # -32(%rbp) := novoBloco
    subq $32, %rsp 

    movq %rdi, %r8 # num_bytes

    movq $0, %rdi
    movq $12, %rax
    syscall                         # %rax := sbrk(0)
    movq %rax, -8(%rbp)             # topo := sbrk(0)

    movq prevAlloc, %rax
    movq %rax, -16(%rbp)            # temp := prevAlloc

    movq $0, -24(%rbp)              # retry := 0

    nf_while1:
        cmpq $1, -24(%rbp)
        jg nf_fim_while1            # while (retry <= 1)

        nf_while2:
            movq -16(%rbp), %rax    # rax = temp
            cmpq -8(%rbp), %rax     # while (temp != topo)
            je nf_fim_while2

            movq -16(%rbp), %rax    # rax = temp
            cmpq $0, (%rax)
            jne nf_fim_if1             # if (temp[0] == 0) && ...

            movq -16(%rbp), %rax    # rax := temp
            cmpq %r8, 8(%rax)       # if (temp[1] >= num_bytes)
            jl nf_fim_if1            

            movq -16(%rbp), %rax    # rax := temp
            movq $1, (%rax)         # temp[0] := 1

            movq %r8, %rax          # rax := num_bytes
            addq $16, %rax          # rax := num_bytes + 16
            movq -16(%rbp), %rbx    # rbx := temp
            cmpq %rax, 8(%rbx)      # if (temp[1] >= num_bytes + 16)
            jl nf_fim_if2

            movq -16(%rbp), %rax    # rax := temp
            addq $16, %rax          # temp := temp + 16
            addq %r8, %rax          # temp := temp + 16 + num_bytes
            movq %rax, -32(%rbp)    # novoBloco := temp + 16 + num_bytes

            movq $0, (%rax)         # novoBloco[0] := 0
            
            movq -16(%rbp), %rbx
            movq 8(%rbx), %rbx      # rbx := temp[1]
            subq %r8, %rbx          # rbx := temp[1] - num_bytes
            subq $16, %rbx          # rbx := temp[1] - num_bytes - 16
            movq %rbx, 8(%rax)      # novoBloco[1] = temp[1] - num_bytes - 16

            movq -16(%rbp), %rax
            movq %r8, 8(%rax)       # temp[1] := num_bytes
            nf_fim_if2:
            
            movq -16(%rbp), %rax    # rax := temp
            addq 8(%rax), %rax      # rax := temp + temp[1]
            addq $16, %rax          # rax := temp + temp[1] + 16
            movq %rax, prevAlloc    # prevAlloc := (long *)((char *)temp + temp[1] + 16)
            
            movq -16(%rbp), %rax    # rax := temp
            addq $16, %rax          # rax := temp + 16
            addq $32, %rsp
            popq %rbp
            ret                     # return &temp[2]
            nf_fim_if1:

            movq -16(%rbp), %rax    # rax := temp
            addq 8(%rax), %rax      # rax := temp + temp[1]
            addq $16, %rax          # rax := temp + temp[1] + 16
            movq %rax, -16(%rbp)    # temp := (long *)((char *)temp + temp[1] + 16)

            jmp nf_while2
        nf_fim_while2:

        movq topoInicialHeap, %rax
        movq %rax, -16(%rbp)        # temp := topoInicialHeap
        addq $1, -24(%rbp)          # ++retry

        jmp nf_while1
    nf_fim_while1:

    # sinaliza como ocupado e armazena tam de memória a ser alocado
    movq -8(%rbp), %rdi             # rdi := brk(0)
    addq $16, %rdi
    addq %r8, %rdi
    movq $12, %rax
    syscall                         # brk((char *)topo + 16 + num_bytes)
    movq %rax, prevAlloc            # prevAlloc = (long *)((char *)topo + 16 + num_bytes)

    movq -8(%rbp), %rax             # rax := topo
    movq $1, (%rax)                 # topo[0] := 1L
    movq %r8, 8(%rax)               # topo[1] := num_bytes

    addq $16, %rax                  # rax := topo + 2
    addq $32, %rsp
    popq %rbp
    ret                             # return &topo[2]

.globl firstFit
firstFit:
    pushq %rbp
    movq %rsp, %rbp

    # -8(%rbp) := topo
    # -16(%rbp) := temp
    # -24(%rbp) := maior
    # -32(%rbp) := num_bytes
    # -40(%rbp) := novoBloco
    subq $40, %rsp 

    movq %rdi, -32(%rbp)

    movq $0, %rdi
    movq $12, %rax
    syscall                         # %rax := sbrk(0)
    movq %rax, -8(%rbp)             # topo := sbrk(0)

    movq topoInicialHeap, %rax
    movq %rax, -16(%rbp)            # temp := topoInicialHeap
    movq %rax, -24(%rbp)            # maior := temp

    ff_while1:
        movq -16(%rbp), %rax        # rax = temp
        cmpq -8(%rbp), %rax         # while (temp != topo)
        je ff_fim_while1

        movq -24(%rbp), %rax        # rax = maior
        cmpq $1, (%rax)
        jne ff_fim_while1          # if (maior[0] == 1) && ...

        movq -16(%rbp), %rax        # rax = temp
        cmpq $1, (%rax)
        jne ff_fim_while1           # if (temp[0] == 1)

        movq -16(%rbp), %rax        # rax := temp
        addq 8(%rax), %rax          # rax := temp + temp[1]
        addq $16, %rax              # rax := temp + temp[1] + 16
        movq %rax, -16(%rbp)        # temp := (long *)((char *)temp + temp[1] + 16)
        
        jmp ff_while1
    ff_fim_while1:

    movq -16(%rbp), %rax
    movq %rax, -24(%rbp)            # maior := temp

    ff_while2:
        movq -16(%rbp), %rax        # rax = temp
        cmpq -8(%rbp), %rax         # while (temp != topo)
        je ff_fim_while2

        movq -16(%rbp), %rax        # rax = temp
        cmpq $0, (%rax)
        jne ff_fim_if1              # if (temp[0] == 0) && ...

        movq -16(%rbp), %rax        # rax := temp
        movq -24(%rbp), %rbx        # rbx := maior
        movq 8(%rbx), %rbx          # rbx := maior[1]
        cmpq %rbx, 8(%rax)          # if (temp[1] > maior[1])
        jle ff_fim_if1            
        
        movq -16(%rbp), %rax
        movq %rax, -24(%rbp)        # maior := temp
        ff_fim_if1:

        movq -16(%rbp), %rax        # rax := temp
        addq 8(%rax), %rax          # rax := temp + temp[1]
        addq $16, %rax              # rax := temp + temp[1] + 16
        movq %rax, -16(%rbp)        # temp := (long *)((char *)temp + temp[1] + 16)

        jmp ff_while2
    ff_fim_while2:

    movq -24(%rbp), %rax        # rax = maior
    cmpq -8(%rbp), %rax         # if (temp != maior) && ...
    je ff_fim_if2

    movq -32(%rbp), %rax        # rax := num_bytes
    addq $16, %rax              # rax := num_bytes + 16
    movq -24(%rbp), %rbx        # rbx := maior
    cmpq %rax, 8(%rbx)          # if (maior[1] >= num_bytes + 16)
    jl ff_fim_if2

    movq -24(%rbp), %rax        # rax := maior
    movq $1, (%rax)             # maior[0] := 1

    movq -32(%rbp), %rax        # rax := num_bytes
    addq $16, %rax              # rax := num_bytes + 16
    movq -24(%rbp), %rbx        # rbx := maior
    cmpq %rax, 8(%rbx)          # if (maior[1] >= num_bytes + 16)
    jl ff_fim_if7

    movq -24(%rbp), %rax        # rax := maior
    addq $16, %rax              # maior := maior + 16
    addq -32(%rbp), %rax        # maior := maior + 16 + num_bytes
    movq %rax, -40(%rbp)        # novoBloco := maior + 16 + num_bytes

    movq $0, (%rax)             # novoBloco[0] := 0
    
    movq -24(%rbp), %rbx
    movq 8(%rbx), %rbx          # rbx := maior[1]
    subq -32(%rbp), %rbx        # rbx := maior[1] - num_bytes
    subq $16, %rbx              # rbx := maior[1] - num_bytes - 16
    movq %rbx, 8(%rax)          # novoBloco[1] = maior[1] - num_bytes - 16

    movq -24(%rbp), %rax
    movq -32(%rbp), %rbx
    movq %rbx, 8(%rax)          # maior[1] := num_bytes
    ff_fim_if7:

    addq $16, %rax              # rax := topo + 2
    addq $40, %rsp
    popq %rbp
    ret                         # return &topo[2]
    ff_fim_if2:

    # sinaliza como ocupado e armazena tam de memória a ser alocado
    movq -8(%rbp), %rdi         # rdi := brk(0)
    addq $16, %rdi
    addq -32(%rbp), %rdi
    movq $12, %rax
    syscall                     # brk((char *)topo + 16 + num_bytes)

    movq -8(%rbp), %rax         # rax := topo
    movq $1, (%rax)             # topo[0] := 1L
    movq -32(%rbp), %rbx
    movq %rbx, 8(%rax)          # topo[1] := num_bytes

    addq $16, %rax              # rax := topo + 2
    addq $40, %rsp
    popq %rbp
    ret                         # return &topo[2]




.globl alocadorV2
alocadorV2:
    pushq %rbp
    movq  %rsp, %rbp

    mov %rdi, tamAloc            # salva o tamanho da alocacao
    mov topoInicialHeap, %r10    # Salva o topo da heap em r10

    mov  $12, %rax               # codigo referente ao brk
    mov  $0 , %rdi               # 0 para retornar o topo da heap
    syscall                      # executa a sycall
    movq %rax, topoAtualHeap     # retorno em %rax e salvo em topoAtualHeap

    v2_w0: 
        cmpq %r10 , topoAtualHeap # compara o topo inicial (r10) com o topo atual (rax)
        je v2_fim_w0              # fim do loop, não tinha um espaço disponivel, é necessário alocar um novo

        mov (%r10), %r15          # bloco de "livre ou não"  -> r15
        cmp $0    , %r15          # se ocupado, procura proximo bloco
        jne v2_prox_bloc_1

        mov %r10     , %r14       # compara se o tamanho disponível é o suficiente para alocar 
        add $8       , %r10       # o novo tamanho
        mov (%r10)   , %r15 
        cmpq tamAloc , %r15
        jl  v2_prox_bloc_2

        mov $1      ,  %r13       # se nao está ocupado e tem tamanho o suficiente 
        mov %r13    , (%r14)
        movq tamAloc,  %r14
        mov %r14    , (%r15)

        add $8      , %r15 

        mov %r15    , %rax 
        

        jmp v2_fim_aloc              # Termina a alocação

        v2_prox_bloc_1:
        add $8       , %r10
        mov (%r10)   , %r15

        v2_prox_bloc_2:
        add $8       , %r10

        add %r15     , %r10

        jmp v2_w0

    # Não tinha um espaço disponivel, é necessário alocar um novo
    v2_fim_w0:

    mov  $12, %rax               # codigo referente ao brk
    mov  $0 , %rdi               # 0 para retornar o topo da heap
    syscall                      # executa a sycall

    mov %rax    , %r15           # salva o local atual
    
   
    addq tamAloc, %rax           # soma o tamanho da alocação
    add  $16    , %rax           # soma o espaço do cabecalho

    mov %rax    , %rdi           # move o tamanho para a chamado do brk
    mov  $12    , %rax           # codigo referente ao brk
    syscall                      # executa a sycall

    mov $1       ,  %r14         # a[0] espaco alocado
    mov %r14     , (%r15)        #
    add $8       ,  %r15         # a[1]
    movq tamAloc ,  %r14         # 
    mov %r14     , (%r15)        # a[1] = tamanho
    mov %r15     , %rax
    add $8       , %rax

    v2_fim_aloc:
    popq %rbp

    ret


.globl liberaMem
liberaMem:
    pushq %rbp
    movq %rsp, %rbp

    # -8(%rbp) := topo
    # -16(%rbp) := temp
    # -24(%rbp) := ret
    # -32(%rbp) := prev
    # -40(%rbp) := next
    subq $40, %rsp  

    movq %rdi, -16(%rbp)            # temp := block
    movq $0, -24(%rbp)              # ret := 0

    movq $0, %rdi
    movq $12, %rax
    syscall
    movq %rax, -8(%rbp)             # topo := sbrk(0)

    movq -16(%rbp), %rax
    cmpq $1, -16(%rax)              # if (temp[-2] == 1L)
    jne fim_if3
    movq -16(%rbp), %rax
    movq $0, -16(%rax)              # temp[-2] := 0L
    movq $1, -24(%rbp)              # ret := 1
    fim_if3:
    
    movq topoInicialHeap, %rax
    movq %rax, -32(%rbp)            # prev := topoInicialHeap

    addq 8(%rax), %rax              # rax := prev + prev[1]
    addq $16, %rax                  # rax := prev + prev[1] + 16
    movq %rax, -40(%rbp)            # next := (long *)((char *)prev + prev[1] + 16)

    while3:
        movq -8(%rbp), %rax
        cmpq -40(%rbp), %rax        # while (next != topo)
        je fim_while3

        movq $0, %r8                # x := 0

        while4:
            movq -32(%rbp), %rax
            cmpq $0, (%rax)
            jne fim_while4          # prev[0] == 0L && ...

            movq -40(%rbp), %rax
            cmpq $0, (%rax)
            jne fim_while4          # next[0] == 0L && ...

            movq -8(%rbp), %rax
            cmpq -40(%rbp), %rax    # while (next != topo)
            je fim_while4

            movq -40(%rbp), %rax
            movq 8(%rax), %rax      # rax := next[1]
            movq -32(%rbp), %rbx    # rbx := prev
            addq %rax, 8(%rbx)      # prev[1] += next[1]
            addq $16, 8(%rbx)       # prev[1] += next[1] + 16

            movq -32(%rbp), %rax    # rax := prev
            addq 8(%rax), %rax      # rax := prev + prev[1]
            addq $16, %rax          # rax := prev + prev[1] + 16
            movq %rax, -40(%rbp)    # next = (long *)((char *)prev + prev[1] + 16)

            movq $1, %r8            # x := 1
            jmp while4
        fim_while4:

        movq -40(%rbp), %rax
        movq %rax, -32(%rbp)        # prev = next

        cmpq $0, %r8
        jne fim_if4                 # if (x == 0)
        movq -32(%rbp), %rax        # rax := prev
        addq 8(%rax), %rax          # rax := prev + prev[1]
        addq $16, %rax              # rax := prev + prev[1] + 16
        movq %rax, -40(%rbp)        # next := (long *)((char *)prev + 16 + prev[1])
        fim_if4:

        jmp while3
    fim_while3:

    movq -16(%rbp), %rax            # rax := temp
    addq -8(%rax), %rax             # rax := temp + temp[-1]
    movq %rax, prevAlloc            # prevAlloc = (long *)(temp[-1] + (char *)temp)

    movq -24(%rbp), %rax
    addq $40, %rsp
    popq %rbp
    ret                             # return ret

.globl printMapa
printMapa:
    pushq %rbp
    movq %rsp, %rbp

    # -8(%rbp) := count 
    # -16(%rbp) := topoAtual
    # -24(%rbp) := c
    subq $24, %rsp 

    movq topoInicialHeap, %rax
    movq %rax, -8(%rbp)             # count := topoInicialHeap

    movq $0, %rdi                   # primeiro parâmetro brk
    movq $12, %rax                  # No de syscall do brk
    syscall                         # brk(0)
    movq %rax, -16(%rbp)            # topoAtual := sbrk(0)

    while5:
        movq -8(%rbp), %rax
        movq -16(%rbp), %rbx
        cmpq %rbx, %rax             # while (count != topoAtual)
        je fim_while5

        # print '################'
        movq $0, %rax
        movq $str_cabc, %rdi
        call printf

        # condicional e loop p/ printar caracteres '+' ou '-'
        movq -8(%rbp), %rax         # rax := count
        cmpq $1, (%rax)
        jne minus_sign              # se count[0] == 0 vai pra minus_sign
        mov plus_char, %r10         # r10 = '+'
        jmp for1_set
        minus_sign:
        mov minus_char, %r10        # r10 = '-'

        for1_set:
            movq $0, %r11           # r11 := i = 0
            movq -8(%rbp), %rax     # rax := count
            movq 8(%rax), %r12      # r12 := count[1]
        for1:
            cmpq %r12, %r11         # for (int i = 0; i < count[1]; i++)
            jge fim_for1

            movq %r10, %rdi
            call putchar            # printa + ou -

            addq $1, %r11           # i++

            jmp for1
        fim_for1:

        movq -8(%rbp), %rax         # rax := count
        addq 8(%rax), %rax          # rax := count + count[1]
        addq $16, %rax              # rax := count + count[1] + 16
        movq %rax, -8(%rbp)         # count := (long *)((char *)count + a[1] + 16)

        jmp while5
    fim_while5:

    movq $10, %rdi                  # char de fim de linha
    call putchar
    movq $10, %rdi                  # char de fim de linha
    call putchar

    addq $24, %rsp
    popq %rbp
    ret
