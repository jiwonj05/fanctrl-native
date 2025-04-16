#!/bin/bash

# Add current directory to PYTHONPATH
export PYTHONPATH="$(pwd)/bindings:$(pwd)/src"

# Run the Python entry point or CLI
fw-fanctrl run
