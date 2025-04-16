import ctypes
import os

lib = ctypes.CDLL(os.path.join(os.path.dirname(__file__), "libdemo_ectool.so"))

lib.get_sensor_count.restype = ctypes.c_uint8
lib.set_fan_speed.argtypes = [ctypes.c_uint8]
lib.set_fan_speed.restype = None
lib.pause_fan_control.restype = None
lib.is_on_ac_power.restype = ctypes.c_bool

class sensor_list(ctypes.Structure):
    _fields_ = [
        ("id", ctypes.c_uint8),
        ("label", ctypes.c_char * 32),
        ("temperature_c_decideg", ctypes.c_uint16),
        ("is_battery", ctypes.c_bool)
    ]

lib.get_sensors.restype = ctypes.POINTER(sensor_list)

count = lib.get_sensor_count()
ptr = lib.get_sensors()

for i in range(count):
    sensor = ptr[i]
    print(f"Sensor {i}: ID={sensor.id}, Label={sensor.label.decode()}, Temp={sensor.temperature_c_decideg / 10.0}°C, Battery={sensor.is_battery}")

def print_all_sensors():
    count = lib.get_sensor_count()
    ptr = lib.get_sensors()
    for i in range(count):
        s = ptr[i]
        print(f"Sensor {i}: ID={s.id}, Label={s.label.decode()}, Temp={s.temperature_c_decideg / 10.0}°C, Battery={s.is_battery}")

def get_sensors():
    return lib.get_sensors()

def get_sensor_count():
    return lib.get_sensor_count()

def set_fan_speed(speed):
    return lib.set_fan_speed(speed)

def pause_fan_control():
    lib.pause_fan_control()

def is_on_ac_power():
    return lib.is_on_ac_power()

# Test
if __name__ == "__main__":
    print("AC Connected:", is_on_ac_power())
    print("Pausing fan control...")
    pause_fan_control()
    print_all_sensors()
    print("Setting fan speed to 70%...")
    lib.set_fan_speed(70)