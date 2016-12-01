SRC=$(wildcard src/*.c)

CFLAGS += -std=c99 -D_GNU_SOURCE
CC ?= $(CROSSCOMPILER)gcc

UNAME := $(shell uname)

ifeq ($(UNAME),MSYS_NT-6.1)
	TARGET	= priv/native/baud.exe
	SOURCES	= src/baud-msys2.c src/baud.c src/util.c src/loop.c
else
	TARGET	= priv/native/baud
	SOURCES = src/baud-posix.c src/baud.c src/util.c src/loop.c
endif

OBJ=$(SOURCES:.c=.o)

.PHONY: all clean

all: $(TARGET)

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

$(TARGET): $(OBJ)
	mkdir -p priv/native
	$(CC) $^ -o $@

clean:
	rm -f priv/native/* src/*.o
