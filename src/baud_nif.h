
#ifndef _BAUD_NIF_H_
#define _BAUD_NIF_H_

#define UNUSED(x) (void)(x)
#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAXPATH 255

#ifdef _WIN32
#include <windows.h>
#else
#include <termios.h>
#endif

typedef struct BAUD_RESOURCE {
  #ifdef _WIN32
  HANDLE handle;
  #else
  int fd;
  #endif
  char path[MAXPATH + 1];
  char device[MAXPATH + 1];
  char config[3 + 1];
} BAUD_RESOURCE;

int serial_open(BAUD_RESOURCE *res, int speed);
size_t serial_available(BAUD_RESOURCE *res);
size_t serial_read(BAUD_RESOURCE *res, unsigned char *buffer, int size);
size_t serial_write(BAUD_RESOURCE *res, unsigned char *buffer, int size);
int serial_close(BAUD_RESOURCE *res);
int serial_release(BAUD_RESOURCE *res);

#endif
