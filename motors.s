@arquivo para as funcoes do motors
set_motor_speed_handler:
    stmfd sp!, {r4}                 @ empilha r4, callee-save

    mov r3, #4                      @ r3 é a constante para acessar a posicao correta da pilha
                                    @ SYSCALL_HANDLER empilha lr e stmfd empilha r4

    ldrb r0, [sp, -r3]              @ r0 o id do motor a ser setado
    add r3, r3, #4                  @ ajusta o r3 para acessar a proxima posicao da pilha
    ldrb r1, [sp, -r3]              @ em r1 a velocidade do motor

    cmp r1, #0x40                   @ verifica se a velocidade eh menor que 64
    bhi invalid_m_speed         @ spd > 64 = invalid_motor_speed

    cmp r0, #1                      @ verifica se o id do motor eh maior que 1
    bhi invalid_m_id            @ id > 1 = invalid_motor_id
    beq valid_m1_speed      @ id = 1 = setar o motor 1

    valid_m0_id:            @ caso o id seja valido, testar a velocidade
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


    valid_m1_speed:          @ valores validos para velocidade e id
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

    invalid_m_speed:            @ velocidade invalida para motor
        mov r0, #-2                 @ retorna -2
        ldmfd sp!, {r4}             @desempiplha r4
        mov pc, lr                  @ retorna da funcao set_motor_speed

    invalid_m_id:               @ caso o id do motor seja invalido retornar -1
        mov r0, #-1                 @ retorna -1 em caso de erro
        ldmfd sp!, {r4}             @ desempilha r4
        mov pc, lr                  @ retorna do tratamento

set_motors_speed_handler:
    stmfd sp!, {r4, r5}             @ empilha r4 e r5

    mov r3, #8                      @ r3 é a constante para acessar a posicao correta da pilha
                                    @ SYSCALL_HANDLER empilha lr e stmfd empilha r4

    ldrb r0, [sp, -r3]              @ r0 a velocidade do primeiro motor a ser setado
    add r3, r3, #4                  @ ajusta o r3 para acessar a proxima posicao da pilha
    ldrb r1, [sp, -r3]              @ em r1 a velocidade do segundo motor a ser setado

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

        ldmfd sp!, {r4, r5}                 @ desempilha r4
        mov r0, #0                      @ retorna 0 para a funcao
        mov pc, lr

    invalid_m0_spd:
        mov r0, #-1
        ldmfd sp!, {r4,r5}
        mov pc, lr

    invalid_m1_spd:
        mov r0, #-2
        ldmfd sp!, {r4,r5}
        mov pc, lr
