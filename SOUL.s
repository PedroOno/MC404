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
.set STACK_SUP_ADRESS,      0x80000000
.set STACK_SYS_ADRESS,      0x7FFFFE00
.set STACK_IRQ_ADRESS,      0x7FFFFC00

@processor modes
.set USER,                  0b10000
.set FIQ,                   0b10001
.set IRQ,                   0b10010
.set SUPERVISOR,            0b10011
.set SYSTEM,                0b11111

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

        @test
		@bl inicializa_alarmes							@ Inicializa as flags do vetor de alarmes

    SET_STACK:
        msr CPSR_c, #0x1F                               @ seta o modo de operacao como system
        ldr r0, =STACK_SYS_ADRESS                       @ endereco da pilha no system/user
        mov sp, r0                                      @ seta o stack pointer no system

        msr CPSR_c, #0x12                               @ seta o modo de operacao como IRQ
        ldr r0, =STACK_IRQ_ADRESS                       @ endereco da pilha do IRQ
        mov sp, r0                                      @ seta o stack pointer no IRQ

        msr CPSR_c, #0x13                               @seta o modo de operacao como SUPERVISOR
        ldr r0, =STACK_SUP_ADRESS                       @ endereco da pilha de supervisor
        mov sp, r0                                                @ seta o stack pointer no IRQ

@test realmente vai pro programa de usuario
GOTO_USER:
    msr CPSR_c, #0x10
    ldr r0, =tTEXT
    mov pc, r0
    @@ test
    @mov r1, # 60        @ tempo
    @ldr r0, = 0xffffffff    @ endereco
    @mov r7, #22
    @
    @stmfd sp!, {r0-r1}
    @svc 0x0
    @ldmfd sp!, {r0-r1}

    @test
    @b RESET_HANDLER


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Funcoes auxiliares do RESET_HANDLER                                          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@inicializa_alarmes:
@    ldr r0, = struct_alarmes							@ Endereco do vetor de alarmes
@    mov r1, #0x00										@ Valor de inicializacao
@    mov r2, #0											@ Indice do vetor
@    ldr r3, = MAX_ALARMS								@ Numero maximo de alarmes
@
@loop_inicializa_alarmes:
@    cmp r2, r3
@    bhs fim_loop_inicializa_alarmes						@ Verifica se chegou ao final do vetor
@    strb r1, [r0]										@ Registra o valor na memoria
@    add r2, r2, #1										@ Incrementa o indice
@    add r0, r0, #9										@ Atualiza o endereco
@    b loop_inicializa_alarmes
@
@fim_loop_inicializa_alarmes:
@
@    mov pc, lr                                          @ Retorno da funcao

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
	bleq set_motor_speed_handler

	cmp r7, #19                                     @ set motors speed
	bleq set_motors_speed_handler

	cmp r7, #20                                     @ get time
	@bleq GET_TIME

	cmp r7, #21                                     @ set time
	@bleq SET_TIME

	cmp r7, #22                                     @ set alarm
	bleq SET_ALARM

	ldr r2, =0x78787878							@ Troca o modo de operacao
	cmp r7, r2
	bleq MODE_CHANGE

	ldmfd sp!, {lr}                                 @ recupera o link register da pilha

	movs pc, lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@arquivo para as funcoes do motors
set_motor_speed_handler:

    stmfd sp!, {r4, r5}                 @ empilha r4, callee-save

    mov r3, #0                      @ r3 é a constante para acessar a posicao correta da pilha
                                    @ SYSCALL_HANDLER empilha lr e stOmfd empilha r4

    ldr r0, =SYSTEM                 @mudar o codigo para modo system
    msr CPSR_c, r0

    ldrb r0, [sp, r3]                @ r0 o id do motor a ser setado
    add r3, r3, #4                  @ ajusta o r3 para acessar a proxima posicao da pilha
    ldrb r1, [sp, r3]                @ em r1 a velocidade do motor

    ldr r3, =SUPERVISOR                 @mudar o codigo para modo SUPERVISOR
    msr CPSR_c, r3

    cmp r1, #63                   @ verifica se a velocidade eh menor que 64
    bhi invalid_m_speed         @ spd > 64 = invalid_motor_speed

    cmp r0, #1                      @ verifica se o id do motor eh maior que 1
    bhi invalid_m_id            @ id > 1 = invalid_motor_id
    beq valid_m1_speed      @ id = 1 = setar o motor 1

    valid_m0_id:            @ caso o id seja valido, testar a velocidade
        ldr r2, =GPIO_DR                        @ carrega endereco do GPIO_DR
        ldr r3, [r2]                            @ carrega valor do GPIO_DR

        ldr r0, =MOTOR_WRITE_0_MASK                          @ setar o write motor 1 para 0
        bic r3, r3, r0
        str r3, [r2]                            @ manda para o GPIO_DR

        ldr r4, =MOTOR_SPEED_0_MASK     @ mascara para zerar a velocidade no input
        bic r3, r3, r4                          @ zera os bits da velocidade

        orr r3, r3, r1, lsl #19                       @ coloca os bits do motor no r3, para depois enviar para o GPIO_DR

        str r3, [r2]                            @ manda para o GPIO_DR

        mov r0, #0                      @ retorna 0 para a funcao
        b return_set_m_spd

    valid_m1_speed:          @ valores validos para velocidade e id
        ldr r2, =GPIO_DR                       @ carrega endereco do GPIO_DR
        ldr r3, [r2]                            @ carrega valor do GPIO_DR

        ldr r0, =MOTOR_WRITE_1_MASK                          @ setar o write motor 1 para 0
        bic r3, r3, r0
        str r3, [r2]                            @ manda para o GPIO_DR

        ldr r4, =MOTOR_SPEED_1_MASK     @ mascara para zerar a velocidade no input
        bic r3, r3, r4                          @ zera os bits da velocidade

        orr r3, r3, r1, lsl #26                       @ coloca os bits do motor no r3, para depois enviar para o GPIO_DR

        str r3, [r2]                            @ manda para o GPIO_DR

        mov r0, #0                      @ retorna 0 para a funcao
        b return_set_m_spd

    invalid_m_speed:            @ velocidade invalida para motor
        mov r0, #-2                 @ retorna -2
        b return_set_m_spd

    invalid_m_id:               @ caso o id do motor seja invalido retornar -1
        mov r0, #-1                 @ retorna -1 em caso de erro
        b return_set_m_spd

    return_set_m_spd:
        ldmfd sp!, {r4, r5}             @ desempilha r4
        mov pc, lr                  @ retorna do tratamento

set_motors_speed_handler:
    stmfd sp!, {r4, r5}             @ empilha r4 e r5

    mov r3, #0                      @ r3 é a constante para acessar a posicao correta da pilha
                                    @ SYSCALL_HANDLER empilha lr e st0mfd empilha r4

    mrs r0, CPSR
    ldr r0, =SYSTEM                 @mudar o codigo para modo system
    msr CPSR_c, r0

    ldrb r0, [sp, -r3]              @ r0 a velocidade do primeiro motor a ser setado
    add r3, r3, #4                  @ ajusta o r3 para acessar a proxima posicao da pilha
    ldrb r1, [sp, -r3]              @ em r1 a velocidade do segundo motor a ser setado

    ldr r3, =SUPERVISOR                 @mudar o codigo para modo SUPERVISOR
    msr CPSR_c, r3

    cmp r0, #0x40                   @ compara velocidade do motor 0 com o limite 64
    bhi invalid_m0_spd

    cmp r1, #0x40
    bhi invalid_m1_spd

    valid_m_speed:
        ldr r2, =GPIO_DR                        @ carrega endereco do GPIO_DR
        ldr r3, [r2]                            @ carrega valor do GPIO_DR

        ldr r4, =MOTOR_SPEED_0_MASK     @ mascara para zerar a velocidade 0 no input
        ldr r5, =MOTOR_SPEED_1_MASK     @ mascara para zerar a velocidade 1 no input
        add r4, r4, r5                  @ mascara para zerar os bits de velocidade dois motores
        bic r3, r3, r4                          @ zera os bits da velocidade

        mov r0, r0, lsl #19             @ move bits do valor da velocidade para os bits do motor0
        mov r1, r1, lsl #26             @ move bits do valor da velocidade para os bits do motor1
        add r0, r0, r1                  @ coloca os bits de velocidade dos dois motores a serem setados
        orr r3, r0, r3                          @ coloca os bits do motor no r3, para depois enviar para o GPIO_DR

        str r3, [r2]                            @ manda para o GPIO_DR

        mov r0, #0                      @ retorna 0 para a funcao
        b return_set_ms_spd

    invalid_m0_spd:
        mov r0, #-1
        b return_set_ms_spd

    invalid_m1_spd:
        mov r0, #-2
        b return_set_ms_spd

    return_set_ms_spd:
        ldmfd sp!, {r4,r5}
        mov pc, lr




@ Syscall read_sonar
@ Parametro:
@ 	[sp]: Identificador do sonar (valores válidos: 0 a 15).
@ Retorno:
@ 	r0: Valor obtido na leitura dos sonares; -1 caso o identificador do sonar seja inválido
READ_SONAR:
	stmfd sp!, {r4-r11, lr}

    @ O parametro sera encontrado na pilha do usario/system, para isso temos que mudar para esse modo


    ldr r0, =SYSTEM                 @ mudar o codigo para modo system
    msr CPSR_c, r0                  @ muda para o modo de operacao System

    ldrb r1, [sp]					@ recupera o parametro e salva em r1

    ldr r3, =SUPERVISOR             @ mudar o codigo para modo SUPERVISOR
    msr CPSR_c, r3                  @ volta para o modo Supervisor e recupera o cpsr anterior

	@ nesse momento o parametro esta em r1
	@ verificacao do parametro
	cmp r1, #15
	movhi r0, #-1
	bhi	fim_READ_SONAR								@ Retorna -1 indicando erro


	ldr r0, = GPIO_DR  @ leitura do sensor
	ldr r2, [r0]   @ obtem o conteudo do GPIO_DR

	mov r1, r1, lsl #2								@ desloca o identificador para a posicao correta

    ldr r3, =TRIGGER_MASK   @  mascara do bit do trigger para o sonar
    ldr r4, =SONAR_MUX_MASK @ mascara dos 4 bits do id do sonar
    add r3, r3, r4  @ soma as mascaras para zerar o trigger e os bits de saida
	bic r2, r2, r3 	@ limpa os bits do SONAR_MUX e reseta o trigger

	add r2, r2, r1 @ coloca o identificador
	str r2, [r0]   @ grava o identificador em GPIO_DR

    stmfd sp!, {r0-r3}  @ empilha registradores caller-save
    mov r0, #15    @ aguarda aproximadamente 15 ms
	bl delay_sonar
    ldmfd sp!, {r0-r3} @desempilha registradores caller-save

	@ seta o trigger
	ldr r2, [r0]									@ Obtem o conteudo do GPIO_DR
    ldr r1, =TRIGGER_MASK   @ carrega a mascara do trigger
	add r2, r2, r1			@ seta o trigger
	str r2, [r0]			@ atualiza o GPIO_DR

	@ Aguarda aproximadamente 15 ms
    stmfd sp!, {r0-r3}  @ empilha registradores caller-save
    mov r0, #15
	bl delay_sonar
    ldmfd sp!, {r0-r3} @desempilha registradores caller-save

    @ reseta o trigger
	ldr r2, [r0]									@ Obtem o conteudo do GPIO_DR
    ldr r1, =TRIGGER_MASK   @ carrega a mascara do trigger
	add r2, r2, r1			@ seta o trigger
	str r2, [r0]			@ atualiza o GPIO_DR

    espera_flag:
    	ldr r2, [r0]									@ Obtem o conteudo do GPIO_DR
    	and r3, r2, #0x1								@ Seleciona o valor da flag
    	cmp r3, #0x1									@ Verifica se a flag esta setada
    	beq fim_espera_flag

        stmfd sp!, {r0-r3}  @ empilha registradores caller-save
        mov r0, #10										@ Aguarda aprox. 10 ms
    	bl delay_sonar
        ldmfd sp!, {r0-r3} @desempilha registradores caller-save
    	b espera_flag

    fim_espera_flag:

    	@ Nesse momento a leitura esta em SONAR_DATA e precisa ser extraida
    	mov r2, r2, lsr #0x6								@ Desloca a leitura para os bits menos significativos
        ldr r1, =0xFFF
    	and r2, r2, r1
        mov r1, r2									@ Limpa os bits restantes
    	mov r0, r1										@ Move para r0 o valor de retorno

    fim_READ_SONAR:
    	ldmfd sp!, {r4-r11, pc}							@ Retorna para o tratador de syscalls.


@ delay_sonar
@ Aguarda r0 milisegundos (idealmente)
@ Parametro:
@	r0: Tempo em milisegundo a ser aguardado
delay_sonar:
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

    mrs r2, CPSR									@ move para r0 o conteudo de cprs para nao perde-lo
	msr CPSR, #0x1F                               	@ Muda para o modo de operacao System

    ldr r0, [sp]									@ Recupera o endereco da funcao do alarme
    ldr r1, [sp, #4]								@ Recupera o tempo de acionamento do alarme

    msr CPSR, r2 	                             	@ Volta para o modo Supervisor e recupera o cpsr anterior

	ldr r4, = num_alarms
	ldr r4, [r4]									@ Numero de alarmes ativos

	ldr r5, = MAX_ALARMS							@ Numero maximo de alarmes

	cmp r4, r5
	beq max_ultrapassado							@ Verifica se ja foi atingido o numero maximo de alarmes

	ldr r2, = SYSTEM_TIME
	ldr r2, [r2]									@ Obtem tempo do sistema

	cmp r2, r1										@ Caso o tempo em que o alarme iria ser
	bhi tempo_invalido								@ programado ja passou nao eh possivel criar esse alarme

	ldr r6, = struct_alarmes						@ Endereco dos alarmes
	mov r7, #0										@ indice do vetor de alarmes

loop_set_alarme:

	ldrb r2, [r6]
	cmp r2, #0x01 									@ Verifica se a posicao esta livre,
	beq loop_set_alarme								@ ou seja, nao possui alarmes ativos

	mov r2, #0x01									@ Seta flag indicando que a posicao esta ocupada
	strb r2, [r6]									@ a partir desse momento

	str r1, [r6, #1] 								@ Registra o tempo do alarme
	str r0, [r6, #5]								@ Registra o endereco da funcao a ser chamada

	add r4, r4, #1
	ldr r0, = num_alarms
	str r4, [r0]									@ Atualiza o numero de alarmes

	mov r0, #0										@ Retorno que indica que o alarme foi criado com sucesso

	b fim_set_alarme

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
	stmfd sp!, {r0-r12, lr}							@ Salva o estado completo para nao prejudicar o codigo do usuario
    ldr r0, =GPT_SR             					@ avisar que houve interrupcao
    mov r1, #0x1
    str r1, [r0]

	@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@2222222 HABILITA INTERRUPCOES
    ldr r0, =SYSTEM_TIME        					@ somar 1 ao contador
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]

    ldr r2, = BUSY_HANDLER							@ Verifica se o ultimo tratamento dos alarmes nao foi finalizado
    ldrb r2, [r2]									@ Em caso positivo a verificacao sera realizada na proxima
    cmp r2, #0x001									@ Atualizacao do tempo do sistema
    beq fim_irq_handler

    stmfd sp!, {r0-r3}
    bl trata_alarmes								@ Trata os alarmes pendentes
    ldmfd sp!, {r0-r3}

fim_irq_handler:
    sub lr, lr, #4              					@ Corrige valor de lr
    ldmfd sp!, {r0-r12, lr}								@ Recupera o estado anterior
    movs pc, lr										@ Retorna para o modo anterior e recupera as flags


@ Essa funcao trata os alarmes ja criados pelo usuario
@ Se ja estiver na hora de acionar o alarme, eh executada sua
@ instrucao especifica e em seguida ele eh retirado do vetor de alarmes

trata_alarmes:
	stmfd sp!, {r4-r11,lr}
	ldr r0, = BUSY_HANDLER							@ Seta flag indicando que o tratador esta ocupado
	mov r1, #1
	strb r1, [r0]

	ldr r0, = MAX_ALARMS                           @ r0 recebe o tamanho do vetor de alarmes

	mov r1, #0										@ indice dos alarmes vistos

	ldr r2, = alarm_vector							@ Endereco do vetor de alarmes
	mov r4, r2										@ Base para o deslocamento para acesso ao vetor

loop_alarms:
	cmp r1, r0										@ Compara o indice com o numero de maximo de alarmes
	bhs fim_loop_alarms								@ Verifica se todos os alarmes foram verificados

	@ Verifica se a posicao do vetor esta disponivel para um novo alarme
	ldrb r3, [r4]									@ Primeiro byte eh uma flag com esse proposito
	cmp r3, #0x01'									@ Caso r3 = 1, quer dizer que a posicao esta ocupada
	beq passo                                       @ Então verifique a proxima posicao do vetor

	@ Verifica se jah esta na hora de acionar o alarme
	ldr r3, [r4, #1]								@ Obtem o tempo em que o alarme atual deve ser acionado
	ldr r6, = SYSTEM_TIME

	ldr r6, [r6]									@ Obtem o tempo do sistema
	cmp r3, r6
	blo passo										@ Ainda nao esta na hora de ser acionado

	mov r3, #0										@ Reseta a flag que indica que esse alarme esta liberado
	strb r3, [r4]

	@ Executa a instrucao contida no endereco do alarme
	@ Para isso temos que mudar para o modo de usuario
	@ Antes de fazer isso iremos salvar o cpsr para podermos voltar ao modo IRQ
	mrs r6, CPSR									@ move para r6 o conteudo de cpsr

    msr CPSR_c, #0x10 								@ Muda para o modo usuario

	ldr r3, [r4, #5]								@ Carrega a instucao no r3
	stmfd sp!, {r0-r11}								@ Salva o contexto atual (todos sao salvos para garantir
													@ que um erro do usuario comprometa o sistema)
	blx r3											@ executa a funcao a ser chamada na ocorrencia do alarme
	ldmfd sp!, {r0-r11}								@ Recupera o contexto atual

	@ Agora temos que voltar para o modo IRQ utilizaremos uma syscall
	stmfd sp!, {r6}									@ Parametro com o cpsr que queremos ficar
	ldr r7, =0x78787878								@ Identificador da syscall
	svc 0x0 										@ Chamada da syscal

	@ Nesse momento, o modo IRQ foi retornado, podemos continuar a execucao do loop
	@ Atualizacao do numero de alarmes ativos
	ldr r3, = num_alarms
	ldr r7, [r3]
	sub r7, r7, #1				@ Subtrai uma alarme, o qual ja foi tratado
	str r7, [r3]				@ Atualiza a variavel na memoria

passo:
	add r1, r1, #1				@ Incrementa o valor do indice
	add r4, r3, #9				@ deslocamento para o proximo elemento da struct
	b loop_alarms				@ Salta para o inicio do loop

fim_loop_alarms:

	ldr r0, = BUSY_HANDLER		@ Reseta flag indicando que o tratador esta livre
	mov r1, #0
	strb r1, [r0]

	ldmfd sp!, {r4-r11, pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
.data
SYSTEM_TIME: 	.word 0           	@ SYSTEM_TIME inicializa com 0
alarm_vector:   .word 0             @test

@ Vetor de structs, onde cada elemento representa um alarm
@ Cada elemento eh composto por 9 bytes, destes:
@	O primeiro eh utilizado como uma flag que indica se o alarme:
@			 1) Posicao livre, sem alarme: Valor = 0x00
@			 2) Posicao ocupada, com alarme em espera de ser adcionado: Valor = 0x01
@	Os proximos quatro bytes sao utilizados para registrar o tempo de sistema em que o alarme devera ser tocado
@	Os ultimos quatro bytes armazenam o endereco da instrucao que sera chamada quando o alarme atingir o tempo definido
@ 1 byte 4 bytes para o endereco da instrucao desse alarme 4 bytes para o tempo do sistema do alarme e
struct_alarmes: 		.skip 64	@ Vetor de "structs" dos alarmes
num_alarms:				.word 0		@ Numero de alarmes criados
BUSY_HANDLER:			.byte 0		@ Flag que indica se o tratador de alarmes esta ocupado (valor 1) ou livre (valor 0)
