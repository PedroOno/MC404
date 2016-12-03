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

/*
 * Sets motor speed.
 * Parameter:
 *   motor: pointer to motor_cfg_t struct containing motor id and motor speed
 * Returns:
 *   void
 */
set_motor_speed:
    stmfd sp!, {r4-r11, lr}         @empilha registradores e lr para retorno da funcao
    ldrb r1, [r0]                   @carrega em r1 o id do motor a ser setado

    cmp r1, #1                      @verifica se o id do motor eh maior que 1
    bhi invalid_motor_id            @comparacao sem sinal

    cmp r1, #0                      @verifica se o id do motor eh menor que 0
    blo invalid_motor_id

    b valid_motor_id

    invalid_motor_id:               @caso o id do motor seja invalido retornar -1
        mov r0, #-1
        ldmfd sp!, {r4-r11, pc}     @retorna da funcao set_motor_speed

    valid_motor_id:                 @caso o id seja valido, testar a velocidade
        ldrb r2, [r0, #1]           @carrega a velocidade em r2
        cmp r2, #0                  @verifica se a velocidade eh negativa
        blo invalid_motor_speed     @se for negativa eh invalida
        b valid_set_motor_speed     @se for positiva os valores sao validos

    invalid_motor_speed:            @velocidade invalida para motor
        mov r0, #-2                 @retorna -2
        ldmfd sp!, {r4-r11, pc}     @retorna da funcao set_motor_speed

    valid_set_motor_speed:          @valores validos para velocidade e id
        mov r0, r1                  @r0 = id
        mov r1, r2                  @r1 = velocidade
        mov r7, #18                 @syscall do set_motor_speed
        svc 0x0                     @chamada da syscall

ldmfd sp!, {r4-r11, pc}         @retorna da funcao set_motor_speed
