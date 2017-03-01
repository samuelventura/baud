ERLANG_H = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
CFLAGS = -fPIC -std=c99 -D_GNU_SOURCE -pedantic-errors -Wall -Wextra -I$(ERLANG_H)
LFLAGS = -shared -dynamiclib -undefined dynamic_lookup
UNAME := $(shell uname)
SRCDIR   = src
OBJDIR   = obj

ifeq (MSYS_NT,$(findstring MSYS_NT,$(UNAME)))
	TARGET	= priv/baud_nif.dll
	SOURCES	= src/baud_win32.c src/baud_nif.c
else
	TARGET	= priv/baud_nif.so
	SOURCES = src/baud_posix.c src/baud_nif.c
endif

OBJECTS := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

.PHONY: all clean

all: $(TARGET)

$(OBJECTS): $(OBJDIR)/%.o : $(SRCDIR)/%.c
	mkdir -p $(OBJDIR)
	$(CC) $(CFLAGS) -o $@ -c $<

$(TARGET): $(OBJECTS)
	$(CC) $(LFLAGS) -o $@ $^

clean:
	rm -f obj/*
	rm -f priv/*
