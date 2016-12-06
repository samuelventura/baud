UNAME := $(shell uname)

ifeq (MSYS_NT,$(findstring MSYS_NT,$(UNAME)))
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
