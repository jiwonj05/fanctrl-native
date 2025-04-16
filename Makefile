# Shared library
LIB_NAME = libdemo_ectool.so

# Compiler and Flags
CC = gcc
CFLAGS = -fpic -shared
SRC = bindings/demo_ectool.c
HDR = bindings/demo_ectool.h
LIB_NAME = bindings/libdemo_ectool.so

all: $(LIB_NAME)

$(LIB_NAME): $(SRC) $(HDR)
	$(CC) -o $@ $(CFLAGS) $^

run: all
	./run.sh

clean:
	rm -f $(LIB_NAME)
