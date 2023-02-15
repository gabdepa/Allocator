.section .data
    topoInicialHeap:    .quad 0
    topoBlocos:         .quad 0
    prevAlloc:          .quad 0
    .equ INCREMENT, 4096
    .equ TAM_HEADER, 16
    
.globl topoInicialHeap
.globl prevAlloc
.globl topoBlocos

    str_init:           .string "Init printf() heap arena\n"
    str_cabc:           .string "################"
    plus_char:          .byte 43
    minus_char:         .byte 45

.section .text

.globl iniciaAlocador
iniciaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    # Inicializa buffer do printf() alocado na heap
    movq $0, %rax              # parâmetros variádicos printf (nulo)
    movq $str_init, %rdi       # primeiro parâmetro printf
    call printf

    # Obtêm topo inicial da heap
    movq $0, %rdi              # primeiro parâmetro brk
    movq $12, %rax             # No de syscall do brk
    syscall                    # brk(0)
    movq %rax, topoInicialHeap # topo da heap (retorno de brk)
    movq %rax, prevAlloc       # prevAlloc := topoInicialHeap
    
    movq %rax, topoBlocos      # topoBlocos = sbrk(0) adicionado para best fit

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

.globl nextFit
nextFit:
    pushq %rbp
    movq %rsp, %rbp

    subq $32, %rsp # -8(%rbp) := topo ; -16(%rbp) := tmp ;
                   # -24(%rbp) := segunda_tentativa ;
                   # -32(%rbp) := novoBloco
    movq %rdi, %r8 # num_bytes

    movq $0, %rdi
    movq $12, %rax
    syscall                         # %rax := sbrk(0)
    movq %rax, -8(%rbp)             # topo := sbrk(0)

    movq prevAlloc, %rax
    movq %rax, -16(%rbp)            # tmp := prevAlloc

    movq $0, -24(%rbp)              # segunda_tentativa := 0

    nf_while1:
        cmpq $1, -24(%rbp)
        jg nf_fim_while1               # while (segunda_tentativa <= 1)

        nf_while2:
            movq -16(%rbp), %rax    # rax = tmp
            cmpq -8(%rbp), %rax     # while (tmp != topo)
            je nf_fim_while2

            movq -16(%rbp), %rax    # rax = tmp
            cmpq $0, (%rax)
            jne nf_fim_if1             # if (tmp[0] == 0) && ...

            movq -16(%rbp), %rax    # rax := tmp
            cmpq %r8, 8(%rax)       # if (tmp[1] >= num_bytes)
            jl nf_fim_if1            

            movq -16(%rbp), %rax    # rax := tmp
            movq $1, (%rax)         # tmp[0] := 1

            movq %r8, %rax          # rax := num_bytes
            addq $16, %rax          # rax := num_bytes + 16
            movq -16(%rbp), %rbx    # rbx := tmp
            cmpq %rax, 8(%rbx)      # if (tmp[1] >= num_bytes + 16)
            jl nf_fim_if2

            movq -16(%rbp), %rax    # rax := tmp
            addq $16, %rax          # tmp := tmp + 16
            addq %r8, %rax          # tmp := tmp + 16 + num_bytes
            movq %rax, -32(%rbp)    # novoBloco := tmp + 16 + num_bytes

            movq $0, (%rax)         # novoBloco[0] := 0
            
            movq -16(%rbp), %rbx
            movq 8(%rbx), %rbx      # rbx := tmp[1]
            subq %r8, %rbx          # rbx := tmp[1] - num_bytes
            subq $16, %rbx          # rbx := tmp[1] - num_bytes - 16
            movq %rbx, 8(%rax)      # novoBloco[1] = tmp[1] - num_bytes - 16

            movq -16(%rbp), %rax
            movq %r8, 8(%rax)       # tmp[1] := num_bytes
            nf_fim_if2:
            
            movq -16(%rbp), %rax    # rax := tmp
            addq 8(%rax), %rax      # rax := tmp + tmp[1]
            addq $16, %rax          # rax := tmp + tmp[1] + 16
            movq %rax, prevAlloc    # prevAlloc := (long *)((char *)tmp + tmp[1] + 16)
            
            movq -16(%rbp), %rax    # rax := tmp
            addq $16, %rax          # rax := tmp + 16
            addq $32, %rsp
            popq %rbp
            ret                     # return &tmp[2]
            nf_fim_if1:

            movq -16(%rbp), %rax    # rax := tmp
            addq 8(%rax), %rax      # rax := tmp + tmp[1]
            addq $16, %rax          # rax := tmp + tmp[1] + 16
            movq %rax, -16(%rbp)    # tmp := (long *)((char *)tmp + tmp[1] + 16)

            jmp nf_while2
        nf_fim_while2:

        movq topoInicialHeap, %rax
        movq %rax, -16(%rbp)        # tmp := topoInicialHeap
        addq $1, -24(%rbp)          # ++segunda_tentativa

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

    subq $40, %rsp # -8(%rbp) := topo ; -16(%rbp) := tmp ;
                   # -24(%rbp) := maior ; -32(%rbp) := num_bytes ; -40(%rbp) := novoBloco
    movq %rdi, -32(%rbp)

    movq $0, %rdi
    movq $12, %rax
    syscall                         # %rax := sbrk(0)
    movq %rax, -8(%rbp)             # topo := sbrk(0)

    movq topoInicialHeap, %rax
    movq %rax, -16(%rbp)            # tmp := topoInicialHeap
    movq %rax, -24(%rbp)            # maior := tmp

    ff_while1:
        movq -16(%rbp), %rax    # rax = tmp
        cmpq -8(%rbp), %rax     # while (tmp != topo)
        je ff_fim_while1

        movq -24(%rbp), %rax    # rax = maior
        cmpq $1, (%rax)
        jne ff_fim_while1          # if (maior[0] == 1) && ...

        movq -16(%rbp), %rax    # rax = tmp
        cmpq $1, (%rax)
        jne ff_fim_while1          # if (tmp[0] == 1)

        movq -16(%rbp), %rax    # rax := tmp
        addq 8(%rax), %rax      # rax := tmp + tmp[1]
        addq $16, %rax          # rax := tmp + tmp[1] + 16
        movq %rax, -16(%rbp)    # tmp := (long *)((char *)tmp + tmp[1] + 16)
        
        jmp ff_while1
    ff_fim_while1:

    movq -16(%rbp), %rax
    movq %rax, -24(%rbp)    # maior := tmp

    ff_while2:
        movq -16(%rbp), %rax    # rax = tmp
        cmpq -8(%rbp), %rax     # while (tmp != topo)
        je ff_fim_while2

        movq -16(%rbp), %rax    # rax = tmp
        cmpq $0, (%rax)
        jne ff_fim_if1             # if (tmp[0] == 0) && ...

        movq -16(%rbp), %rax    # rax := tmp
        movq -24(%rbp), %rbx    # rbx := maior
        movq 8(%rbx), %rbx      # rbx := maior[1]
        cmpq %rbx, 8(%rax)      # if (tmp[1] > maior[1])
        jle ff_fim_if1            
        
        movq -16(%rbp), %rax
        movq %rax, -24(%rbp)    # maior := tmp
        ff_fim_if1:

        movq -16(%rbp), %rax    # rax := tmp
        addq 8(%rax), %rax      # rax := tmp + tmp[1]
        addq $16, %rax          # rax := tmp + tmp[1] + 16
        movq %rax, -16(%rbp)    # tmp := (long *)((char *)tmp + tmp[1] + 16)

        jmp ff_while2
    ff_fim_while2:

    movq -24(%rbp), %rax    # rax = maior
    cmpq -8(%rbp), %rax     # if (tmp != maior) && ...
    je ff_fim_if2

    movq -32(%rbp), %rax    # rax := num_bytes
    addq $16, %rax          # rax := num_bytes + 16
    movq -24(%rbp), %rbx    # rbx := maior
    cmpq %rax, 8(%rbx)      # if (maior[1] >= num_bytes + 16)
    jl ff_fim_if2

    movq -24(%rbp), %rax    # rax := maior
    movq $1, (%rax)         # maior[0] := 1

    movq -32(%rbp), %rax    # rax := num_bytes
    addq $16, %rax          # rax := num_bytes + 16
    movq -24(%rbp), %rbx    # rbx := maior
    cmpq %rax, 8(%rbx)      # if (maior[1] >= num_bytes + 16)
    jl ff_fim_if7

    movq -24(%rbp), %rax    # rax := maior
    addq $16, %rax          # maior := maior + 16
    addq -32(%rbp), %rax    # maior := maior + 16 + num_bytes
    movq %rax, -40(%rbp)    # novoBloco := maior + 16 + num_bytes

    movq $0, (%rax)         # novoBloco[0] := 0
    
    movq -24(%rbp), %rbx
    movq 8(%rbx), %rbx      # rbx := maior[1]
    subq -32(%rbp), %rbx    # rbx := maior[1] - num_bytes
    subq $16, %rbx          # rbx := maior[1] - num_bytes - 16
    movq %rbx, 8(%rax)      # novoBloco[1] = maior[1] - num_bytes - 16

    movq -24(%rbp), %rax
    movq -32(%rbp), %rbx
    movq %rbx, 8(%rax)      # maior[1] := num_bytes
    ff_fim_if7:

    addq $16, %rax          # rax := topo + 2
    addq $40, %rsp
    popq %rbp
    ret                     # return &topo[2]
    ff_fim_if2:

    # sinaliza como ocupado e armazena tam de memória a ser alocado
    movq -8(%rbp), %rdi             # rdi := brk(0)
    addq $16, %rdi
    addq -32(%rbp), %rdi
    movq $12, %rax
    syscall                         # brk((char *)topo + 16 + num_bytes)

    movq -8(%rbp), %rax             # rax := topo
    movq $1, (%rax)                 # topo[0] := 1L
    movq -32(%rbp), %rbx
    movq %rbx, 8(%rax)              # topo[1] := num_bytes

    addq $16, %rax                  # rax := topo + 2
    addq $40, %rsp
    popq %rbp
    ret                             # return &topo[2]

.globl bestFit
bestFit:
    pushq %rbp
    movq %rsp, %rbp
    subq $88, %rsp

    # VARIÁVEIS:
    #   -8(%rbp)  long int bestFit;
    #   -16(%rbp) long int *cabecalho;
    #   -24(%rbp) void *iterator;
    #   -32(%rbp) void *comecoBloco;
    #   -40(%rbp) long int *isDisp;
    #   -48(%rbp) long int disp;
    #   -56(%rbp) long int mult;
    #   -64(%rbp) long int excesso;
    #   -72(%rbp) long int *bloco;
    #   -80(%rbp) long int *brk
    #   -88(%rbp) long int num_bytes

    #  salva parâmetro na stack
    movq %rdi, -88(%rbp)

    # if (num_bytes <= 0) return NULL
    cmpq $0, %rdi
    jge bf_fimIf1

    movq $0, %rax
    popq %rbp
    ret
    bf_fimIf1:
    movq $0, -8(%rbp)
    movq topoInicialHeap, %r8
    movq %r8, -24(%rbp)
    movq topoBlocos, %r8
    movq %r8, -32(%rbp)

    #  while (iterator < topoBlocos)
    bf_while:
    movq -24(%rbp), %r8
    movq topoBlocos, %r9
    cmpq %r9, %r8
    jge bf_fimwhile

    #  cabecalho = iterator
    movq %r8, -16(%rbp)
    
    #  if !cabecalho[0]
    movq (%r8), %r8
    movq $0, %r9
    cmpq %r9, %r8
    jne bf_fimIf

    #  if cabecalho[1] >= num_bytes
    movq -16(%rbp), %r8
    movq 8(%r8), %r8
    movq -88(%rbp), %rdi
    cmpq %rdi, %r8
    jl bf_fimIf

    # if ((cabecalho[1] < bestFit) || !bestFit)
    movq -8(%rbp), %r9
    cmpq %r9, %r8
    jl bf_dentroIf
    
    movq $0, %r10
    cmpq %r9, %r10
    jne bf_fimIf

    bf_dentroIf:
    # bestFit = cabecalho[1]
    movq %r8, -8(%rbp)

    #  comecoBloco = iterator
    movq -24(%rbp), %r9
    movq %r9, -32(%rbp)

    bf_fimIf:
    #  iterator += TAM_HEADER + cabecalho[1]
    movq -16(%rbp), %r8
    movq 8(%r8), %r8
    addq $TAM_HEADER, %r8
    addq %r8, -24(%rbp)

    jmp bf_while
    bf_fimwhile:

    #  if (bestfit)
    movq -8(%rbp), %r8
    movq $0, %r9
    cmpq %r9, %r8
    je bf_fimIf2

    #  isDisp = comecobloco
    movq -32(%rbp), %r8
    #  *isDisp = 1
    movq $1, (%r8)

    #  return comecoBloco + TAM_HEADER
    addq $TAM_HEADER, %r8
    movq %r8, %rax

    addq $88, %rsp
    popq %rbp
    ret

    bf_fimIf2:

    #  sbrk(0)
    movq $0, %rdi
    movq $12, %rax
    syscall
    movq %rax, -80(%rbp)

    #  disp = sbrk(0) - topoBlocos
    movq topoBlocos, %r8
    subq %rax, %r8
    movq %r8, -48(%rbp)

    #  if (TAM_HEADER + num_bytes > disp)
    movq $TAM_HEADER, %r8
    movq -88(%rbp), %rdi
    addq %rdi, %r8
    movq -48(%rbp), %r9
    cmpq %r9, %r8
    jle bf_endif3

    # excesso = TAM_HEADER + num_bytes - disp
    subq %r9, %r8
    movq %r8, -64(%rbp)
    #  mult = 1 + ((excesso - 1)/INCREMENT)
    subq $1, %r8
    movq %r8, %rax
    xor %rdx, %rdx
    movq $INCREMENT, %r9
    idiv %r9
    addq $1, %rax
    imul $INCREMENT, %rax

    #  sbrk(INCREMENT * mult)
    addq -80(%rbp), %rax
    movq %rax, %rdi
    movq $12, %rax
    syscall

    bf_endif3:
    
    #  bloco = topoBlocos
    movq topoBlocos, %r8
    movq %r8, -72(%rbp)
    #  bloco[0] = 1
    movq $1, (%r8)
    #  bloco[1] = num_bytes
    movq -88(%rbp), %rdi
    movq %rdi, 8(%r8)
    #  topoBlocos += TAM_HEADER + num_bytes
    movq topoBlocos, %r9
    addq $TAM_HEADER, %r9
    addq %rdi, %r9
    movq %r9, topoBlocos

    #  return bloco + HEADER_SIZE
    movq -72(%rbp), %rax
    addq $TAM_HEADER, %rax
    
    addq $88, %rsp
    popq %rbp
    ret


.globl liberaMem
liberaMem:
    pushq %rbp
    movq %rsp, %rbp
    subq $40, %rsp  # -8(%rbp) := topo ; -16(%rbp) := tmp ; -24(%rbp) := ret
                    # -32(%rbp) := prev ; -40(%rbp) := next

    movq %rdi, -16(%rbp)            # tmp := block
    movq $0, -24(%rbp)              # ret := 0

    movq $0, %rdi
    movq $12, %rax
    syscall
    movq %rax, -8(%rbp)             # topo := sbrk(0)

    movq -16(%rbp), %rax
    cmpq $1, -16(%rax)              # if (tmp[-2] == 1L)
    jne fim_if3
    movq -16(%rbp), %rax
    movq $0, -16(%rax)              # tmp[-2] := 0L
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

    movq -16(%rbp), %rax        # rax := tmp
    addq -8(%rax), %rax         # rax := tmp + tmp[-1]
    movq %rax, prevAlloc        # prevAlloc = (long *)(tmp[-1] + (char *)tmp)

    movq -24(%rbp), %rax
    addq $40, %rsp
    popq %rbp
    ret                        # return ret

.globl printMapa
printMapa:
    pushq %rbp
    movq %rsp, %rbp
    subq $24, %rsp # -8(%rbp) := a ; -16(%rbp) := topoAtual ; -24(%rbp) := c

    movq topoInicialHeap, %rax
    movq %rax, -8(%rbp)        # a := topoInicialHeap

    movq $0, %rdi              # primeiro parâmetro brk
    movq $12, %rax             # No de syscall do brk
    syscall                    # brk(0)
    movq %rax, -16(%rbp)       # topoAtual := sbrk(0)

    while5:
        movq -8(%rbp), %rax
        movq -16(%rbp), %rbx
        cmpq %rbx, %rax        # while (a != topoAtual)
        je fim_while5

        # print '################'
        movq $0, %rax
        movq $str_cabc, %rdi
        call printf

        # condicional e loop p/ printar caracteres '+' ou '-'
        movq -8(%rbp), %rax     # rax := a
        cmpq $1, (%rax)
        jne minus_sign          # se a[0] == 0 vai pra minus_sign
        mov plus_char, %r10     # r10 = '+'
        jmp for1_set
        minus_sign:
        mov minus_char, %r10    # r10 = '-'

        for1_set:
            movq $0, %r11           # r11 := i = 0
            movq -8(%rbp), %rax     # rax := a
            movq 8(%rax), %r12      # r12 := a[1]
        for1:
            cmpq %r12, %r11      # for (int i = 0; i < a[1]; i++)
            jge fim_for1

            movq %r10, %rdi
            call putchar            # printa + ou -

            addq $1, %r11           # i++

            jmp for1
        fim_for1:

        movq -8(%rbp), %rax     # rax := a
        addq 8(%rax), %rax      # rax := a + a[1]
        addq $16, %rax          # rax := a + a[1] + 16
        movq %rax, -8(%rbp)     # a := (long *)((char *)a + a[1] + 16)

        jmp while5
    fim_while5:

    movq $10, %rdi  # char de fim de linha
    call putchar
    movq $10, %rdi  # char de fim de linha
    call putchar

    addq $24, %rsp
    popq %rbp
    ret