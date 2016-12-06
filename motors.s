set_motor_speed_handler:
    stmfd sp!, {r4}                 @ empilha r4, callee-save

    ldr r3, =8                      @ r3 é a constante para acessar a posicao correta da pilha
                                    @ SYSCALL_HANDLER empilha lr e stmfd empilha r4

    ldrb r0, [sp, -r3]              @ r0 o id do motor a ser setado
    sub r3, r3, #4                  @ ajusta o r3 para acessar a proxima posicao da pilha
    ldrb r1, [sp, -r3]              @ em r1 a velocidade do motor

    cmp r1, #0x40                   @ verifica se a velocidade eh menor que 64
    bhi invalid_motor_speed         @ spd > 64 = invalid_motor_speed

    cmp r0, #1                      @ verifica se o id do motor eh maior que 1
    bhi invalid_motor_id            @ id > 1 = invalid_motor_id
    beq valid_set_motor1_speed      @ id = 1 = setar o motor 1

    valid_set_motor0_id:            @ caso o id seja valido, testar a velocidade
        ldr r2, =GPIO_DR                        @ carrega endereco do GPIO_DR
        ldr r3, [r2]                            @ carrega valor do GPIO_DR

        ldr r4, =MOTOR_SPEED_0_MASK     @ mascara para zerar a velocidade no input
        bic r3, r3, r4                          @ zera os bits da velocidade

        mov r1, r1, lsl #19             @ move bits do valor da velocidade para os bits do motor0
        orr r3, r1, r3                          @ coloca os bits do motor no r3, para depois enviar para o GPIO_DR

        str r3, [r2]                            @ manda para o GPIO_DR

        ldmfd sp!, {r4}                 @ desempilha r4
        mov r0, #0                      @ retorna 0 para a funcao
        mov pc, lr


    valid_set_motor1_speed:          @ valores validos para velocidade e id
        ldr r2, =GPIO_DR                        @ carrega endereco do GPIO_DR
        ldr r3, [r2]                            @ carrega valor do GPIO_DR

        ldr r4, =MOTOR_SPEED_1_MASK     @ mascara para zerar a velocidade no input
        bic r3, r3, r4                          @ zera os bits da velocidade

        mov r1, r1, lsl #26             @ move bits do valor da velocidade para os bits do motor0
        orr r3, r1, r3                          @ coloca os bits do motor no r3, para depois enviar para o GPIO_DR

        str r3, [r2]                            @ manda para o GPIO_DR

        ldmfd sp!, {r4}                 @ desempilha r4
        mov r0, #0                      @ retorna 0 para a funcao
        mov pc, lr

    invalid_motor_speed:            @ velocidade invalida para motor
        mov r0, #-2                 @ retorna -2
        ldmfd sp!, {r4}             @desempiplha r4
        mov pc, lr                  @ retorna da funcao set_motor_speed

    invalid_motor_id:               @ caso o id do motor seja invalido retornar -1
        mov r0, #-1                 @ retorna -1 em caso de erro
        ldmfd sp!, {r4}             @ desempilha r4
        mov pc, lr                  @ retorna do tratamento

set_motors_speed_handler:
    stmfd sp!, {r4, r5}                             @ empilha r4 e r5

    cmp r0, #63
    bhi invalid_motor0

    cmp r0, #0
    blt invalid_motor0

    cmp r1, #63
    bhi invalid_motor1

    cmp r1, #0
    blt invalid_motor1

    ldr r2, =GPIO_DR                                @ Endereco de GPIO_DR
    ldr r3, [r2]                                    @ r3 recebe o valor de GPIO_DR

    ldr r5, =MOTOR_SPEED_0_MASK
    bic r3, r3, r5                                  @ Zera os bits que receberao a velocidade do motor0

    ldr r5, =MOTOR_SPEED_1_MASK
    bic r3, r3, r5                                  @ Zera os bits que receberao a velocidade do motor0

    mov r0, r0, lsl #19                             @ Move bits do valor da velocidade para os bits do motor0
    mov r1, r1, lsl #26                             @ Move bits do valor da velocidade para os bits do motor1

    add r0, r0, r1
    orr r3, r3, r0                                  @ Coloca os bits da velocidade em r3

    str r3, [r2]                                    @ Salva o R3 no GPIO_DR

    mov r0, #0
    ldmfd sp!, {r4 ,r5}
    b BACK_DUMB_USER                                @ Volta para o codigo de usuario

    invalid_motor0:
           mov r0, #-1
           ldmfd sp!, {r4 ,r5}
           movs pc, lr                                     @ Volta para o codigo de usuario

    invalid_motor1:
           mov r0, #-2
           ldmfd sp!, {r4 ,r5}
           b BACK_DUMB_USER                        @ Volta para o codigo de usuario

@arquivo para as funcoes do motors
