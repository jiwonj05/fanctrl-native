# 🌬️ Native Fan Controller with C & Python Binding

This project is a native hardware-level fan controller built from scratch using a shared C library and a Python interface via `ctypes`.

It emulates a hardware environment with temperature sensors and demonstrates how to dynamically control fan speed based on temperature readings. This project is inspired by embedded systems practices and designed to be modular, efficient, and easy to integrate.

---

## 🧠 What I Built

- A native C shared library (`libdemo_ectool.so`) that exposes mock sensor data and fan control functions
- A Python binding layer (`ctypes`) that communicates directly with the C library
- A high-level Python fan controller that implements strategy-based fan speed control
- A clean project structure with `Makefile`, modular source folders, and runtime scripts

---

## 🛠️ Features

- Read sensor data from native C code (ID, label, temperature, battery status)
- Determine highest temperature (with optional filtering for battery sensors)
- Dynamically set fan speed through a C function
- Pause/resume fan control behavior
- Detect if device is on AC power
- Designed to scale: easily add new sensors, strategies, or output logic

---

## 🗂️ Project Structure


