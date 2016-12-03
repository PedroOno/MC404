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

set_motor_speed:
    stmfd sp!, {r4-r11, lr} @empilha registradores e lr para retorno da funcao
    cmp r0, #1
    beq motor_speed_invalid
    mov r7, 18


    motor_speed_invalid:
        mov r0, #-1
    ldmfd sp!, {r4-r11, pc} @desempilha e retorna da funcao
