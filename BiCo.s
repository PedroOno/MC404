@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Description: Uoli Control Application Programming Interface.
@
@ Author: Pedro Gabriel Martins Ono
@
@ Date: 11/2016
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@global functions
.global set_motor_speed
.global set_motors_speed
.global read_sonar
.global read_sonars
.global register_proximity_callback
.global add_alarm
.global get_time
.global set_time

.align 4

@/**************************************************************/
@/* Motors                                                     */
@/**************************************************************/

@/*
@ * Sets motor speed.
@ * Parameter:
@ *   motor: pointer to motor_cfg_t struct containing motor id and motor speed
@ * Returns:
@ *   void
@ */
set_motor_speed:
    stmfd sp!, {r4-r11, lr}         @ empilha registradores e lr para retorno da funcao
    ldr r0, =r0                     @ carrega variavel do motor
    ldrb r1, [r0]                   @ carrega em r1 o id do motor a ser setado

    cmp r1, #1                      @ verifica se o id do motor eh maior que 1
    bhi invalid_motor_id            @ comparacao sem sinal

    cmp r1, #0                      @ verifica se o id do motor eh menor que 0
    blo invalid_motor_id

    b valid_motor_id                @ caso nao seja invalida o id do motor

    invalid_motor_id:               @ caso o id do motor seja invalido retornar -1
        mov r0, #-1
        ldmfd sp!, {r4-r11, pc}     @ retorna da funcao set_motor_speed

    valid_motor_id:                 @ caso o id seja valido, testar a velocidade
        ldrb r2, [r0, #1]           @ carrega a velocidade em r2
        cmp r2, #0                  @ verifica se a velocidade eh negativa
        blo invalid_motor_speed     @ se for negativa eh invalida
        b valid_set_motor_speed     @ se for positiva os valores sao validos

    invalid_motor_speed:            @ velocidade invalida para motor
        mov r0, #-2                 @ retorna -2
        ldmfd sp!, {r4-r11, pc}     @ retorna da funcao set_motor_speed

    valid_set_motor_speed:          @ valores validos para velocidade e id
        stmfd sp!, {r1,r2}          @ empilha os valores de id e velocidade para syscall
        mov r7, #18                 @ syscall do set_motor_speed
        svc 0x0                     @ chamada da syscall
        mov r0, #0                  @ retorna 0 se foi possivel a escrita no motor

ldmfd sp!, {r4-r11, pc}         @ retorna da funcao set_motor_speed

@/*
@ * Sets both motors speed.
@ * Parameters:
@ *   * m1: pointer to motor_cfg_t struct containing motor id and motor speed
@ *   * m2: pointer to motor_cfg_t struct containing motor id and motor speed
@ * Returns:
@ *   void
@ */
set_motors_speed:
    stmfd sp!, {r4-r11, lr}         @ empilha registradores e lr para retorno da funcao
    ldr r0, =r0                     @ carrega variavel do primeiro motor
    ldr r1, =r1                     @ carrega variavel do segundo motor
    ldrb r2, [r0]                   @ carrega em r1 o id do primeiro motor a ser setado
    ldrb r3, [r0, #1]               @ carrega em r2 a velocidade do motor a ser setada
    stmfd sp!, {r2,r3}              @ empilha os valores de id e velocidade do primeiro motor
    mov r7, #18                     @ syscall do set_motor_speed
    svc 0x0                         @ chamada da syscall

    ldrb r2, [r1]                   @ carrega em r1 o id do primeiro motor a ser setado
    ldrb r3, [r1, #1]               @ carrega em r2 a velocidade do motor a ser setada
    stmfd sp!, {r2,r3}              @ empilha os valores de id e velocidade do primeiro motor
    mov r7, #18                     @ syscall do set_motor_speed
    svc 0x0                         @ chamada da syscall

    ldmfd sp!, {r4-r11, pc}         @ retorna da funcao set_motor_speed

@/**************************************************************/
@/* Sonars                                                     */
@/**************************************************************/

@/*
@ * Reads one of the sonars.
@ * Parameter:
@ *   sonar_id: the sonar id (ranges from 0 to 15).
@ * Returns:
@ *   distance of the selected sonar
@ */

read_sonar:
    stmfd sp!, {r4-r11, lr}         @ empilha registradores e lr para retorno da funcao

    cmp r0, #15						@ verifica se id do sonar a ser verificado eh valido
    bhi invalid_sonar

    cmp r0, #0						@ verifica se id do sonar a ser verificado eh valido
    blo invalid_sonar

    stmfd sp!, {r0}                 @ empilha o numero do registrador a ser lido
    mov r7, #16						@ identifica a syscall 16 (read_sonar).
	svc 0x0							@ faz a chamada da syscall.
    ldmfd sp!, {r4-r11, pc}         @ retorna da funcao

    invalid_sonar:
        mov r0, #-1
        ldmfd sp!, {r4-r11, pc}     @ retorna da funcao

read_sonars:
    stmfd sp!, {r4-r11, lr}         @ empilha registradores e lr para retorno da funcao
	mov r4, r0                      @ inicializa o contador r4

	@ Loop para percorrer todos os sensores
	loop_read_sonars:
		cmp r4, r2                      @ se r4 >= end
		bgt end_read_sonars             @ sai do laco
        mov r0, r4                      @ coloca em r0 o sensor a ser verificado
        stmfd sp!, {r0-r3}              @ empilha os registradores caller-save
        b read_sonar                    @ realiza leitura do sonar r4 e salva a leitura em r0
        str r0, [r3]                    @ salva os valor do sensore no vetor
        ldmfd sp!, {r0-r3}              @ desempilha os registradores caller-save
		add r3, r3, #4                  @ ajustar a proxima posicao do vetor a ser escrita
		add r4, r4, #1                  @ ir para o proximo sonar a ser lido
		b loop_read_sonars

	end_read_sonars:
	ldmfd sp!, {r4-r11, pc}             @ Desempilha registradores usados
