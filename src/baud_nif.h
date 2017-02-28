
#ifndef _BAUD_NIF_H_
#define _BAUD_NIF_H_

#define UNUSED(x) (void)(x)

#ifdef _WIN32
#include <windows.h>
#else
#include <termios.h>
#endif

typedef struct BAUD_RESOURCE {
    int fd;
} BAUD_RESOURCE;

int serial_open(BAUD_RESOURCE* res, char* device, int speed, char* config);
size_t serial_available(BAUD_RESOURCE* res);
size_t serial_read(BAUD_RESOURCE* res, unsigned char* buffer, int size);
size_t serial_write(BAUD_RESOURCE* res, unsigned char* buffer, int size);
int serial_close(BAUD_RESOURCE* res);
int serial_release(BAUD_RESOURCE* res);

#endif
