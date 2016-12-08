#include "api_robot2.h" /* Robot control API */

void _start(void){
    motor_cfg_t motor_test, motor_test0;
    unsigned char id0 = 1;
    unsigned char speed0 = 63;
    unsigned char id1 = 1;
    unsigned char speed1 = 63;
    unsigned char id2 = 0;
    unsigned char speed2 = 0;
    unsigned char sonar_id0 = 3;
    motor_test.id = id0;
    motor_test.speed = speed0;
    set_motor_speed(&motor_test);
    id0 = 0;
    speed0 = 63;
    id1 = 1;
    speed1 = 0;
    motor_test.id = id0;
    motor_test.speed = speed0;
    motor_test0.id = id1;
    motor_test0.speed = speed1;
    set_motors_speed(&motor_test, &motor_test0);
    motor_test.id = id2;
    motor_test.speed = speed2;
    set_motor_speed(&motor_test);
    while(1) {
        read_sonar(sonar_id0);
    }
}