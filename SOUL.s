@ constantes para os enderecos do GPT test
.set GPT_CR,                0x53FA0000                 @ GPT Control Register
.set GPT_PR,                0x53FA0004                 @ GPT Prescaler Register
.set GPT_SR,                0x53FA0008                 @ GPT Status Register
.set GPT_IR,                0x53FA000C                 @ GPT Interrupt Register
.set GPT_OCR1,              0x53FA0010                 @ GPT Output Compare Register 1

@ constantes para os enderecos do TZIC
.set TZIC_BASE,             0x0FFFC000
.set TZIC_INTCTRL,          0x0
.set TZIC_INTSEC1,          0x84
.set TZIC_ENSET1,           0x104
.set TZIC_PRIOMASK,         0xC
.set TZIC_PRIORITY9,        0x424

@ registradores GPIO
.set GPIO_DR,               0x53F84000
.set GPIO_GDIR,             0x53F84004
.set GPIO_PSR,              0x53F84008

@ GPIO_SET
.set GPIO_SET_GDIR,         0xFFFC003E

@ linker address
.set tTEXT,                 0x77802000
.set tDATA,                 0x77801800

@ stack address size 50 each
.set STACK_SUP_ADRESS,      0x778018FA
.set STACK_SYS_ADRESS,      0x7780192C
.set STACK_IRQ_ADRESS,      0x7780195E

@ constante para os alarmes
.set MAX_ALARMS, 			0x8
.set TIME_SZ,				1000

@ mascaras de bits
.set TRIGGER_MASK,           0x02
.set SONAR_MUX_MASK,         0x3C
.set SONAR_DATA_MASK,        0x7FF80
.set MOTOR_WRITE_0_MASK,     0x40000
.set MOTOR_WRITE_1_MASK,     0x2000000
.set MOTOR_SPEED_0_MASK,     0x1F80000
.set MOTOR_SPEED_1_MASK,     0xFC000000

.org 0x0
.section .iv,"a"

_start:

interrupt_vector:
    b RESET_HANDLER
    .org 0x8
    b SYSCALL_HANDLER
    .org 0x18
    b IRQ_HANDLER

.org 0x100
.text

RESET_HANDLER:
    ldr r0, =interrupt_vector                       @ set interrupt table base address on coprocessor 15.
    mcr p15, 0, r0, c12, c0, 0

    SET_GPT:

        ldr r2, =SYSTEM_TIME            @ zera o system time
        mov r0, #0
        str r0, [r2]

        ldr r0, =GPT_CR                 @ confirar o GPT
        mov r1, #0x41                   @ habilitar clock no periferico
        str r1, [r0]

        ldr r0, =GPT_PR                 @ zerar o prescaler
        mov r1, #0
        str r1, [r0]

        ldr r0, =GPT_OCR1               @ contar ate 100 o clock
        mov r1, #TIME_SZ
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

    SET_GPIO:
        ldr r0, =GPIO_GDIR                              @ setar cada pino do GPIO como entrada(0) ou saida (1)
        ldr r1, =GPIO_SET_GDIR                          @ salvar essa constante no registrador de direcoes
        str r1, [r0]

    SET_STACK:
        ldr r0, =STACK_SUP_ADRESS                       @ endereco da pilha de supervisor
        mov sp, r0                                      @ seta o stack pointer do supervisor

        msr CPSR_c, #0x1F                               @ seta o modo de operacao como system
        ldr r0, =STACK_SYS_ADRESS                       @ endereco da pilha no system/user
        mov sp, r0                                      @ seta o stack pointer no system

        msr CPSR_c, #0x12                               @ seta o modo de operacao como IRQ
        ldr r0, =STACK_IRQ_ADRESS                       @ endereco da pilha do IRQ
        mov sp, r0                                      @ seta o stack pointer no IRQ

GOTO_USER:
    msr CPSR_c, #0x10
    ldr r0, =tTEXT
    ldr r2, =SYSTEM_TIME  @test
    ldr r2, [r2]          @test
    mov pc, r0

SYSCALL_HANDLER:
    stmfd sp!, {lr}                                 @ salva o link register para retorno

	cmp r7, #16                                     @ read sonar
	@bleq READ_SONAR

	cmp r7, #17                                     @ register proximity callback
    @bleq REGISTER_PROXIMITY_CALLBACK

	cmp r7, #18                                     @ set motor speed
	bleq set_motor_speed_handler

	cmp r7, #19                                     @ set motors speed
	bleq set_motors_speed

	cmp r7, #20                                     @ get time
	@bleq GET_TIME

	cmp r7, #21                                     @ set time
	@bleq SET_TIME

	cmp r7, #22                                     @ set alarm
	@bleq SET_ALARM

	ldmfd sp!, {lr}                                 @ recupera o link register da pilha

	movs pc, lr

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


.include "gpt.s"
.include "sonars.s"
.include "motors.s"

.data
SYSTEM_TIME: .word 0           @ SYSTEM_TIME inicializa com 0
