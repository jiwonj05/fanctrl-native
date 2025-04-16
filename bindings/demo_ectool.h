#ifndef DEMO_ECTOOL_H_
#define DEMO_ECTOOL_H_

/******************************************************************************/
/*                              I N C L U D E S                               */
/******************************************************************************/

#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>

/******************************************************************************/
/*                               D E F I N E S                                */
/******************************************************************************/

// Public defines that may be used by other files

/******************************************************************************/
/*                              T Y P E D E F S                               */
/******************************************************************************/

typedef struct{
    uint8_t id;
    char label[32];
    uint16_t temperature_c_decideg;
    bool is_battery;
} sensor;


/******************************************************************************/
/*                             F U N C T I O N S                              */
/******************************************************************************/

sensor* get_sensors(void);
uint8_t get_sensor_count(void);
void set_fan_sepeed(uint8_t duty_percent);
void pause_fan_control(void);
bool is_on_ac_power(void);

/******************************************************************************/
/*                       I N L I N E  F U N C T I O N S                       */
/******************************************************************************/

// Inline function declarations and implementions

#endif // DEMO_ECTOOL_H_