import re
import subprocess
from abc import ABC

from fw_fanctrl.hardwareController.HardwareController import HardwareController

import demo_binding

class EctoolHardwareController(HardwareController, ABC):
    noBatterySensorMode = False
    nonBatterySensors = None

    def __init__(self, no_battery_sensor_mode=False):
        if no_battery_sensor_mode:
            self.noBatterySensorMode = True
            self.populate_non_battery_sensors()

    def populate_non_battery_sensors(self):
        self.nonBatterySensors = []

        ptr = demo_binding.get_sensors()
        count = demo_binding.get_sensor_count()

        for i in range(count):
            sensor = ptr[i]
            if not sensor.is_battery:
                self.nonBatterySensors.append(sensor.id)

    def get_temperature(self):
        ptr = demo_binding.get_sensors()
        count = demo_binding.get_sensor_count()

        temps = []
        for i in range(count):
            sensor = ptr[i]
            if self.noBatterySensorMode and sensor.id not in self.nonBatterySensors:
                continue
            temps.append(sensor.temperature_c_decideg / 10.0)

        if len(temps) == 0:
            return 50
        return float(round(sorted(temps, reverse=True)[0], 2))


    def set_speed(self, speed):
        demo_binding.set_fan_speed(speed)      

    def is_on_ac(self):
        return demo_binding.is_on_ac_power()

    def pause(self):
        demo_binding.pause_fan_control()

    def resume(self):
        # Empty for ectool, as setting an arbitrary speed disables the automatic fan control
        pass
