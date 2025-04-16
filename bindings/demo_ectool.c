#include "demo_ectool.h"

static sensor sensor_list[3] = {
    {.id = 0, .label = "CPU", .temperature_c_decideg = 402, .is_battery = false},
    {.id = 1, .label = "GPU", .temperature_c_decideg = 603, .is_battery = false},
    {.id = 2, .label = "Battery", .temperature_c_decideg = 423, .is_battery = true}
};

sensor* get_sensors(void){
    return sensor_list;
}

uint8_t get_sensor_count(void) {
    return sizeof(sensor_list) / sizeof(sensor_list[0]);
}

void set_fan_speed(uint8_t duty_percent) {
    printf("Fan speed set to %d%%\n", duty_percent);
}

void pause_fan_control(void) {
    printf("Automatic fan control paused.\n");
}

bool is_on_ac_power(void) {
    return true;
}