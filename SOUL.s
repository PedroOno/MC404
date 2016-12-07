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

@ Processor mode
.set IRQ_MODE,               Ob00010010 @ 18
.set IRQ_MODE_NI,            Ob10010010 @ 146            Desabilita IRQ
.set SUPERVISOR_MODE,        0b10010011 @ 147            Desabilita IRQ
.set USER_MODE,              0b00010000 @ 16
.set SYSTEM_MODE,            0b00011111 @ 31

@ stack address size 400 bytes each
.set STACK_SUP_ADRESS,      0x80000000
.set STACK_SYS_ADRESS,      0x7FFFFE00
.set STACK_IRQ_ADRESS,      0x7FFFFC00

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

        ldr r0, =GPT_OCR1               @ contar ate TIME_SZ o clock
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

	SET_ALARMS:
		mov r1, #0
		ldr r0, = num_alarms
		str r1, [r0]									@ Zera o numero de alarms

		ldr r0, = BUSY_HANDLER							@ Limpa flag do tratador de alarmes
		strb r1, [r0]

		bl inicializa_alarmes							@ Inicializa as flags do vetor de alarmes

    SET_STACK:
        ldr r0, =STACK_SUP_ADRESS                       @ endereco da pilha de supervisor
        mov sp, r0                                      @ seta o stack pointer do supervisor
        ldr r1, = 0xfffafafa@test
        stmfd sp!, {r1}

        msr CPSR_c, #0x1F                               @ seta o modo de operacao como system
        ldr r0, =STACK_SYS_ADRESS                       @ endereco da pilha no system/user
        mov sp, r0                                      @ seta o stack pointer no system
        ldr r1, = 0xccfafafa@test
        stmfd sp!, {r1}

        msr CPSR_c, #0x12                               @ seta o modo de operacao como IRQ
        ldr r0, =STACK_IRQ_ADRESS                       @ endereco da pilha do IRQ
        mov sp, r0                                      @ seta o stack pointer no IRQ
        ldr r1, = 0xeefafafa@test
        stmfd sp!, {r1}

GOTO_USER:
    msr CPSR_c, #0x10
    ldr r0, =tTEXT
@###########################################################################################################################
ldr r0, = 0xfeeeeeee
stmfd sp!, {r0}
@ Codigo de usuario
@ test
    ldr r0, = funcao_inutil    @ endereco
    mov r1, #1        @ tempo
    bl add_alarm
a1:
    ldr r0, = funcao_inutil    @ endereco
    mov r1, #2        @ tempo
    bl add_alarm
a2:
    ldr r0, = funcao_inutil    @ endereco
    mov r1, #3        @ tempo
    bl add_alarm
s3:
    ldr r0, = funcao_inutil    @ endereco
    mov r1, #4        @ tempo
    bl add_alarm
a4:
    ldr r0, = funcao_inutil    @ endereco
    mov r1, #5        @ tempo
    bl add_alarm
a5:
    ldr r0, = funcao_inutil    @ endereco
    mov r1, #6        @ tempo
    bl add_alarm
a6:
    ldr r0, = funcao_inutil    @ endereco
    mov r1, # 7        @ tempo
    bl add_alarm
a7:
    ldr r0, = funcao_inutil    @ endereco
    mov r1, # 8        @ tempo
    bl add_alarm
a8:
b pulo
funcao_inutil:
	and r0, r0, r0
	mov pc, lr
pulo:
loop_infinito:
	b loop_infinito

@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_mode:
    mrs r0, CPSR
    and r1, r0, #0b1000000   @ Flag IRQ
    and r2, r0, #0b10000000  @ Flag FIQ
    and r0, r0, #0b11111111  @ CPSR

@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@ BiCo do Marcelo:

@ add_alarm
@ Adds an alarm to the system
@ Parameters:
@	r0: function to be called when the alarm triggers (void *)
@	r1: the time to invoke the alarm function (unsigned int time)
add_alarm:
	stmfd sp!, {r4-r11, lr}							@ Salva o estado atual dos registradores

	stmfd sp!, {r0,r1}								@ Empilha os parametros da syscall
	mov r7, #22										@ Identificador da syscall set_alarm
	svc 0x0 										@ Chamada da syscall
	ldmfd sp!, {r0,r1} 								@ Desempilha os parametros da syscall

	ldmfd sp!, {r4-r11, pc}							@ Recupera o estado atual dos registradores


@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@###########################################################################################################################

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Funcoes auxiliares do RESET_HANDLER                                          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
inicializa_alarmes:
    ldr r0, = alarm_vector								@ Endereco do vetor de alarmes
    mov r1, #0x00										@ Valor de inicializacao
    mov r2, #0											@ Indice do vetor
    ldr r3, = MAX_ALARMS								@ Numero maximo de alarmes

loop_inicializa_alarmes:
    cmp r2, r3
    bhs fim_loop_inicializa_alarmes						@ Verifica se chegou ao final do vetor
    strb r1, [r0]										@ Registra o valor na memoria
    add r2, r2, #1										@ Incrementa o indice
    add r0, r0, #9										@ Atualiza o endereco
    b loop_inicializa_alarmes

fim_loop_inicializa_alarmes:

    mov pc, lr                                          @ Retorno da funcao

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Tratador de interrupcoes de Syscalls										   @
@ Troca para o modo SUPERVISOR												   @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
SYSCALL_HANDLER:

    stmfd sp!, {lr}                                 @ salva o link register para retorno

	cmp r7, #16                                     @ read sonar
	bleq READ_SONAR

	cmp r7, #17                                     @ register proximity callback
    @bleq REGISTER_PROXIMITY_CALLBACK

	cmp r7, #18                                     @ set motor speed
	@bleq set_motor_speed_handler

	cmp r7, #19                                     @ set motors speed
	@bleq set_motors_speed_handler

	cmp r7, #20                                     @ get time
	@bleq GET_TIME

	cmp r7, #21                                     @ set time
	@bleq SET_TIME

	cmp r7, #22                                     @ set alarm
	bleq SET_ALARM

	ldr r2, =0x78787878							@ Syscall de troca de modo de operacao
	cmp r7, r2
	bleq MODE_CHANGE

	ldmfd sp!, {lr}                                 @ recupera o link register da pilha

	movs pc, lr

@ Syscall read_sonar
@ Parametro:
@ 	[sp]: Identificador do sonar (valores válidos: 0 a 15).
@ Retorno:
@ 	r0: Valor obtido na leitura dos sonares; -1 caso o identificador do sonar seja inválido
READ_SONAR:
	stmfd sp!, {r4-r11, lr}

	@ O parametro sera encontrado na pilha do usario/system, para isso temos que mudar para esse modo

	mrs r0, CPSR									@ move para r0 o conteudo de cprs para nao perde-lo
    ldr r1, = SYSTEM_MODE
	msr CPSR, r1                                  	@ Muda para o modo de operacao System
    ldr r1, [sp]									@ Recupera o parametro e salva em r1
    msr CPSR, r0 	                             	@ Volta para o modo Supervisor e recupera o cpsr anterior

	@ Nesse momento o parametro esta em r1
	@ Verificacao do parametro
	cmp r1, #15
	movhi r0, #-1
	bhi	fim_READ_SONAR								@ Retorna -1 indicando erro


	@ leitura do sensor
	ldr r0, = GPIO_DR
	ldr r2, [r0]									@ Obtem o conteudo do GPIO_DR
	mov r1, r1, lsl #2								@ desloca o identificador para a posicao correta
	bic r2, r2, #0b1111110							@ Limpa os bits do SONAR_MUX e reseta o Trigger
	add r2, r2, r1									@ Adiciona o identificador
	str r2, [r0]									@ Grava o identificador em GPIO_DR

	@ Aguarda aproximadamente 15 ms
	mov r0, #15
	bl delay

	@ Seta o trigger
	ldr r2, [r0]									@ Obtem o conteudo do GPIO_DR
	add r2, r2, #0b10								@ Seta o trigger
	str r2, [r0]									@ Atualiza o GPIO_DR

	@ Aguarda aproximadamente 15 ms
	mov r0, #15
	bl delay

	@ Reseta o trigger
	ldr r2, [r0]									@ Obtem o conteudo do GPIO_DR
	bic r2, r2, #0b10								@ Reseta o trigger
	str r2, [r0]									@ Atualiza o GPIO_DR

espera_flag:
	ldr r2, [r0]									@ Obtem o conteudo do GPIO_DR
	and r3, r2, #0b1								@ Seleciona o valor da flag
	cmp r3, #0b10									@ Verifica se a flag esta setada
	beq fim_espera_flag

	mov r0, #10    @ Aguarda aprox. 10 ms
	bl delay
	b espera_flag
fim_espera_flag:

	@ Nesse momento a leitura esta em SONAR_DATA e precisa ser extraida
	mov r2, r2, lsr #6								@ Desloca a leitura para os bits menos significativos
	and r2, r2, #12									@ Limpa os bits restantes
	mov r0, r2										@ Move para r0 o valor de retorno

fim_READ_SONAR:
	ldmfd sp!, {r4-r11, pc}							@ Retorna para o tratador de syscalls.


@ delay
@ Aguarda r0 milisegundos (idealmente)
@ Parametro:
@	r0: Tempo em milisegundo a ser aguardado
delay:
	stmfd sp!, {r4-r11}
	mov r4, #12										@ Constante de tempo estimada
	mul r4, r0, r4

delay_loop:
	cmp r4, #0
	beq fim_delay_loop
	sub r4, r4, #1
	b delay_loop

fim_delay_loop:
	ldmfd sp!, {r4-r11}
	mov pc, lr


@ Syscall que troca de modo de operacao
@ Parametros:
@ 	p0: copia do cpsr do modo que se deseja mudar (pilha)
@ Essa funcao suja apenas o r3
MODE_CHANGE:
	ldmfd sp!, {r3}
    msr SPSR, r3
    movs pc, lr


@ SET_ALARM
@ Syscal de criacao de alarmes
@ Parametros:
@	P0: ponteiro para funcao a ser chamada na ocorrencia do alarme.
@   P1: tempo do sistema.
@ Retorno:
@	R0:
@		1) -1 caso o número de alarmes máximo ativo no sistema seja maior do que MAX_ALARMS.
@		2) -2 caso o tempo seja menor do que o tempo atual do sistema.
@		3) Caso contrário retorna 0.
SET_ALARM:
	stmfd sp!, {r4-r11, lr}

    mrs r2, CPSR            @ move para r0 o conteudo de cprs para nao perde-lo
    ldr r1, = SYSTEM_MODE
	msr CPSR, r1         @ Muda para o modo de operacao System

    ldr r0, [sp]			@ Recupera o endereco da funcao do alarme
    ldr r1, [sp, #4]		@ Recupera o tempo de acionamento do alarme

    msr CPSR, r2 	        @ Volta para o modo Supervisor e recupera o cpsr anterior

	ldr r4, = num_alarms
	ldr r4, [r4]			@ Numero de alarmes ativos

	ldr r5, = MAX_ALARMS	@ Numero maximo de alarmes

	cmp r4, r5
	beq max_ultrapassado	@ Verifica se ja foi atingido o numero maximo de alarmes

	ldr r2, = SYSTEM_TIME
	ldr r2, [r2]			@ Obtem tempo do sistema

	cmp r2, r1				@ Caso o tempo em que o alarme iria ser
	bhi tempo_invalido		@ programado ja passou nao eh possivel criar esse alarme

	ldr r6, = alarm_vector	@ Endereco dos alarmes
	mov r7, #0				@ indice do vetor de alarmes

loop_set_alarme:
	ldrb r2, [r6]
	cmp r2, #0x01 			@ Verifica se a posicao esta livre,
	beq passo_lp_set_alarm	@ ou seja, nao possui alarmes ativos

	mov r2, #0x01			@ Seta flag indicando que a posicao esta ocupada
	strb r2, [r6]			@ a partir desse momento

	str r1, [r6, #1] 		@ Registra o tempo do alarme
	str r0, [r6, #5]		@ Registra o endereco da funcao a ser chamada

	add r4, r4, #1
	ldr r0, = num_alarms
	str r4, [r0]			@ Atualiza o numero de alarmes

	mov r0, #0				@ Retorno que indica que o alarme foi criado com sucesso

	b fim_set_alarme

passo_lp_set_alarm:
	add r6, r6, #9			@ Salta para o proximo alarme
	b loop_set_alarme

max_ultrapassado:
	mov r0, #-1
	b fim_set_alarme

tempo_invalido:
	mov r0, #-2

fim_set_alarme:
	ldmfd sp!, {r4-r11, lr}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Tratador de interrupcoes													   @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IRQ_HANDLER:
	stmfd sp!, {r0-r12, lr}	@ Salva o estado completo para nao prejudicar o codigo do usuario
    ldr r0, =GPT_SR         @ avisar que houve interrupcao
    mov r1, #0x1
    str r1, [r0]

	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@2222222 HABILITA INTERRUPCOES
    ldr r0, =SYSTEM_TIME    @ somar 1 ao contador
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]

    ldr r2, = BUSY_HANDLER	@ Verifica se o ultimo tratamento dos alarmes nao foi finalizado
    ldrb r2, [r2]			@ Em caso positivo a verificacao sera realizada na proxima
    cmp r2, #0x001			@ Atualizacao do tempo do sistema
    beq fim_irq_handler

    stmfd sp!, {r0-r3}
    bl trata_alarmes		@ Trata os alarmes pendentes
    ldmfd sp!, {r0-r3}

fim_irq_handler:
    sub lr, lr, #4          @ Corrige valor de lr
    ldmfd sp!, {r0-r12, lr}	@ Recupera o estado anterior
    movs pc, lr				@ Retorna para o modo anterior e recupera as flags


@ Essa funcao trata os alarmes ja criados pelo usuario
@ Se ja estiver na hora de acionar o alarme, eh executada sua
@ instrucao especifica e em seguida ele eh retirado do vetor de alarmes

trata_alarmes:
	stmfd sp!, {r4-r11,lr}
	ldr r0, = BUSY_HANDLER	@ Seta flag indicando que o tratador esta ocupado
	mov r1, #1
	strb r1, [r0]

	ldr r0, = MAX_ALARMS    @ r0 recebe o tamanho do vetor de alarmes

	mov r1, #0				@ indice dos alarmes vistos

	ldr r4, = alarm_vector 	@ Endereco do vetor de alarmes

loop_alarms:
	cmp r1, r0				@ Compara o indice com o numero de maximo de alarmes
	bhs fim_loop_alarms		@ Verifica se todos os alarmes foram verificados

	@ Verifica se a posicao do vetor possui um alarme ativos
	ldrb r3, [r4]			@ Primeiro byte eh uma flag com esse proposito
	cmp r3, #0x00			@ Caso r3 = 0, quer dizer que a posicao esta livre (nao tem
	beq passo               @ alarme ativo), portanto essa iteracao do loop sera saltada
@PERGUNTAR PARA O BORIN cmp r3, #0x01									@ Caso r3 = 1, quer dizer que a posicao esta ocupada
@bne passo                                       @ Portanto o seu tempo de acionamento deve ser checado


	@ Verifica se jah esta na hora de acionar o alarme
	ldr r3, [r4, #1]		@ Obtem o tempo em que o alarme atual deve ser acionado

	ldr r6, = SYSTEM_TIME
	ldr r6, [r6]			@ Obtem o tempo do sistema

	cmp r6, r3 				@ Se o tempo do sistema for menor que o do alarme
	blo passo				@ isso quer dizerque ainda nao esta na hora de ser acionado

alarme_acionado:
	mov r3, #0				@ Reseta a flag que indica que esse alarme esta liberado
	strb r3, [r4]			@ na proxima vez que essa funcao for chamada

	@ Executa a instrucao contida no endereco do alarme
	@ Para isso temos que mudar para o modo de usuario
	@ Antes de fazer isso iremos salvar o cpsr para podermos voltar ao modo IRQ
	mrs r6, CPSR			@ move para r6 o conteudo de cpsr
    ldr r10, = USER_MODE
    msr CPSR, r10 		@ Muda para o modo usuario

	ldr r3, [r4, #5]		@ Carrega a instucao no r3
	stmfd sp!, {r0-r11}		@ Salva o contexto atual (todos sao salvos para garantir
							@ que um erro do usuario comprometa o sistema)
	blx r3					@ executa a funcao a ser chamada na ocorrencia do alarme
	ldmfd sp!, {r0-r11}		@ Recupera o contexto atual

	@ Agora temos que voltar para o modo IRQ utilizaremos uma syscall
	stmfd sp!, {r6}			@ Parametro com o cpsr que queremos ficar
	ldr r7, =0x78787878		@ Identificador da syscall
	svc 0x0 				@ Chamada da syscal

	@ Nesse momento, o modo IRQ foi retornado, podemos continuar a execucao do loop
	@ Atualizacao do numero de alarmes ativos
	ldr r3, = num_alarms
	ldr r7, [r3]
	sub r7, r7, #1			@ Subtrai uma alarme, o qual ja foi tratado
	str r7, [r3]			@ Atualiza a variavel na memoria

passo:
	add r1, r1, #1			@ Incrementa o valor do indice
	add r4, r4, #9			@ deslocamento para o proximo elemento da struct
	b loop_alarms			@ Salta para o inicio do loop

fim_loop_alarms:

	ldr r0, = BUSY_HANDLER	@ Reseta flag indicando que o tratador esta livre
	mov r1, #0
	strb r1, [r0]

	ldmfd sp!, {r4-r11, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
.data
test:			.word 0
SYSTEM_TIME: 	.word 0           	@ SYSTEM_TIME inicializa com 0
@ Vetor de structs, onde cada elemento representa um alarm
@ Cada elemento eh composto por 9 bytes, destes:
@	O primeiro eh utilizado como uma flag que indica se o alarme:
@			 1) Posicao livre, sem alarme: Valor = 0x00
@			 2) Posicao ocupada, com alarme em espera de ser adcionado: Valor = 0x01
@	Os proximos quatro bytes sao utilizados para registrar o tempo de sistema em que o alarme devera ser tocado
@	Os ultimos quatro bytes armazenam o endereco da instrucao que sera chamada quando o alarme atingir o tempo definido
@ 1 byte 4 bytes para o endereco da instrucao desse alarme 4 bytes para o tempo do sistema do alarme e
alarm_vector: 		.skip 72	@ Vetor de "structs" dos alarmes
num_alarms:				.word 0		@ Numero de alarmes criados
BUSY_HANDLER:			.byte 0		@ Flag que indica se o tratador de alarmes esta ocupado (valor 1) ou livre (valor 0)
