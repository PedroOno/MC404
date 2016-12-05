@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Description: Uoli Control Application Programming Interface.
@
@ Author: Pedro  Ono 158336
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

set_motor_speed:
    stmfd sp!, {r4-r11, lr}         @ empilha registradores e lr para retorno da funcao

    ldrb r1, [r0]                   @carrega em r1 o id do motor
    ldrb r2, [r0, #1]               @ carrega a velocidade em r2

    stmfd sp!, {r1,r2}              @ empilha os valores de id e velocidade para syscall

    mov r7, #18                     @ syscall do set_motor_speed
    svc 0x0                         @ chamada da syscall

    ldmfd sp!, {r1,r2}              @ desempilha os registradores dos parametros da funcao
    ldmfd sp!, {r4-r11, pc}         @ retorna da funcao set_motor_speed

set_motors_speed:
    stmfd sp!, {r4-r11, lr}         @ empilha registradores e lr para retorno da funcao

    ldrb r2, [r0, #1]               @ carrega em r2 a velocidade do motor a ser setada
    ldrb r3, [r1, #1]               @ carrega em r2 a velocidade do motor a ser setada

    stmfd sp!, {r2, r3}             @ empilha os valores de id e velocidade do primeiro motor

    mov r7, #19                     @ syscall do set_motor_speed
    svc 0x0                         @ chamada da syscall

    ldmfd sp!, {r4-r11, pc}         @ retorna da funcao set_motor_speed

@/**************************************************************/
@/* Sonars                                                     */
@/**************************************************************/

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
        bl read_sonar                   @ realiza leitura do sonar r4 e salva a leitura em r0
        str r0, [r3]                    @ salva os valor do sensore no vetor
        ldmfd sp!, {r0-r3}              @ desempilha os registradores caller-save
		add r3, r3, #4                  @ ajustar a proxima posicao do vetor a ser escrita
		add r4, r4, #1                  @ ir para o proximo sonar a ser lido
		b loop_read_sonars

	end_read_sonars:
	ldmfd sp!, {r4-r11, pc}             @ desempilha registradores usados


register_proximity_callback:
    stmfd sp!, {r4-r11, lr}         @ empilha registradores e o link register

    cmp r0, #15						@ verifica se id do sonar a ser verificado eh valido
    bhi invalid_sonar_rpc

    cmp r0, #0						@ verifica se id do sonar a ser verificado eh valido
    blo invalid_sonar_rpc

    stmfd sp!, {r0-r3}              @ empilha todos os parametros para a chamada da funcao
    mov r7, #17                     @ identifica a syscall 17(register_proximity_callback).
    svc 0x0                         @ faz a chamada da syscall.
    ldmfd sp!, {r4-r11, pc}         @ desempilha registradores usados

    invalid_sonar_rpc:
        mov r0, #-2
        ldmfd sp!, {r4-r11, pc}     @ retorna da funcao

@**************************************************************/
@* Timer                                                      */
@**************************************************************/

add_alarm:
    stmfd sp!, {r4-r11, lr}         @ empilha registradores e o link register
    stmfd sp!, {r0-r1}              @ empilha os parametros da funçao
    mov r7, #22                     @ identifica a syscall 17(set_alarm).
    svc 0x0                         @ faz a chamada da syscall.
    ldmfd sp!, {r4-r11, pc}         @ desempilha registradores usados


get_time:
    stmfd sp!, {r4-r11, lr}         @ empilha registradores e o link register
    mov r1, r0                      @ guarda em r1 o ponteiro para onde o tempo deve ser armazenado
    mov r7, #20                     @ identifica a syscall 17(set_alarm).
    svc 0x0
    str r0, [r1]                    @ guarda o valor de tempo na variavel
    ldmfd sp!, {r4-r11, pc}         @ desempilha registradores usados


set_time:
    stmfd sp!, {r4-r11, lr}         @ empilha registradores e o link register
    stmfd sp!, {r0}                 @ empilha o parametro da funçao
    mov r7, #21                     @ identifica a syscall.
    svc 0x0
    ldmfd sp!, {r4-r11, pc}         @ desempilha registradores usados










