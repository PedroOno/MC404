@Constantes para os enderecos do GPT test
.set GPT_CR,     0x53FA0000                 @ GPT Control Register
.set GPT_PR,     0x53FA0004                 @ GPT Prescaler Register
.set GPT_SR,     0x53FA0008                 @ GPT Status Register
.set GPT_IR,     0x53FA000C                 @ GPT Interrupt Register
.set GPT_OCR1,   0x53FA0010                 @ GPT Output Compare Register 1

@Constantes para os enderecos do TZIC
.set TZIC_BASE,             0x0FFFC000
.set TZIC_INTCTRL,          0x0
.set TZIC_INTSEC1,          0x84
.set TZIC_ENSET1,           0x104
.set TZIC_PRIOMASK,         0xC
.set TZIC_PRIORITY9,        0x424

@ Constante para os alarmes
.set MAX_ALARMS, 			0x8
.set TIME_SZ,				5000

.org 0x0
.section .iv,"a"

_start:

interrupt_vector:
    b RESET_HANDLER
.org 0x18
    b IRQ_HANDLER

.org 0x100
.text

RESET_HANDLER:

    ldr r2, =SYSTEM_TIME            @ zera o system time
    mov r0, #0
    str r0, [r2]

    ldr r0, =interrupt_vector       @ set interrupt table base address on coprocessor 15.
    mcr p15, 0, r0, c12, c0, 0

    ldr r0, =GPT_CR                 @ confirar o GPT
    mov r1, #0x41                   @ habilitar clock no periferico
    str r1, [r0]

    ldr r0, =GPT_PR                 @ zerar o prescaler
    mov r1, #0
    str r1, [r0]

    ldr r0, =GPT_OCR1               @ contar ate 100 o clock
    mov r1, #100
    str r1, [r0]

    ldr r0, =GPT_IR                 @ habilitar a interrupcao
    mov r1, #1
    str r1, [r0]

SET_TZIC:

    @ Liga o controlador de interrupcoes
    @ R1 <= TZIC_BASE

    ldr r1, =TZIC_BASE

    @ Configura interrupcao 39 do GPT como nao segura
    mov r0, #(1 << 7)
    str r0, [r1, #TZIC_INTSEC1]

    @ Habilita interrupcao 39 (GPT)
    @ reg1 bit 7 (gpt)

    mov r0, #(1 << 7)
    str r0, [r1, #TZIC_ENSET1]

    @ Configure interrupt39 priority as 1
    @ reg9, byte 3

    ldr r0, [r1, #TZIC_PRIORITY9]
    bic r0, r0, #0xFF000000
    mov r2, #1
    orr r0, r0, r2, lsl #24
    str r0, [r1, #TZIC_PRIORITY9]

    @ Configure PRIOMASK as 0
    eor r0, r0, r0
    str r0, [r1, #TZIC_PRIOMASK]

    @ Habilita o controlador de interrupcoes
    mov r0, #1
    str r0, [r1, #TZIC_INTCTRL]

    @instrucao msr - habilita interrupcoes
    msr  CPSR_c, #0x13          @ SUPERVISOR mode, IRQ/FIQ enabled

infinityloop:
    b infinityloop

IRQ_HANDLER:
    ldr r0, =GPT_SR             @ avisar que houve interrupcao
    mov r1, #0x1
    str r1, [r0]

    ldr r0, =SYSTEM_TIME        @ somar 1 ao contador
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]

    sub pc, pc, #4              @ corrigir pc subtraindo pc

    movs pc, lr

.data
SYSTEM_TIME: .word 0           @ SYSTEM_TIME inicializa com 0
