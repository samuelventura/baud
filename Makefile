UNAME := $(shell uname)

ifeq ($(UNAME),MSYS_NT-6.1)
	TARGET	= priv/native/baud.exe
	SOURCES	= src/baud-msys2.c src/baud.c src/util.c src/loop.c
else
	TARGET	= priv/native/baud
	SOURCES = src/baud-posix.c src/baud.c src/util.c src/loop.c
endif

all: $(TARGET)

$(TARGET): src/*
	mkdir -p priv/native
	gcc -o $(TARGET) $(SOURCES)

clean:
	rm -f priv/native/*
