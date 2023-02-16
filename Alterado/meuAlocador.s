.section .data
    topoInicialHeap:    .quad 0

    str_init:           .string "Init printf() heap \n"
    str_cabc:           .string "################"
    plus_char:          .byte 43
    minus_char:         .byte 45

    prevAlloc:          .quad 0 # Utilizado no next fit para saber inicio da lista circular 
   
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



.globl alocaMem
alocaMem:
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

    movq -24(%rbp), %rax
    addq $40, %rsp
    popq %rbp
    ret                             # return ret

.globl imprimeMapa
imprimeMapa:
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
