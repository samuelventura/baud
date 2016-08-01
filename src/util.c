#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include "baud.h"

void debug(const char* fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  if (force_debug || context.debug) {
    print_time(" ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\r\n");
    fflush(stderr);
  }
}

void crash(const char* fmt, ...) {
  if (force_debug || context.debug) {
    va_list ap;
    va_start(ap, fmt);
    print_time(" ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\r\n");
    print_time(" ");
    print_last_error();
    fprintf(stderr, "\r\n");
    fflush(stderr);
  }
  context_cleanup();
  exit(-1);
  abort(); //force crash
}

void phex(const char *header, unsigned char *buf, int size) {
  if (force_debug || context.debug) {
    print_time(" ");
    fprintf(stderr, "%s", header);
    for (int i = 0; i < size; i++) {
        fprintf(stderr, "%02X", buf[i]);
    }
    fprintf(stderr, "\r\n");
  }
}

//use only within crash calls since it wont release memory
char* tohex(unsigned char *buf, int size) {
  char* buf_str = (char*) malloc (2*size + 1);
  char* buf_ptr = buf_str;
  for (int i = 0; i < size; i++) {
      buf_ptr += sprintf(buf_ptr, "%02X", buf[i]);
  }
  *(buf_ptr + 1) = '\0';
  return buf_str;
}

unsigned short crc16(unsigned char *buf, int len) {
  unsigned short crc = 0xFFFF;
  for (int pos = 0; pos < len; pos++) {
    crc ^= (unsigned short)buf[pos];
    for (int i = 8; i > 0; i--) {
      if ((crc & 0x0001) != 0) {
        crc >>= 1;
        crc ^= 0xA001;
      }
      else crc >>= 1;
    }
  }
  return crc;
}
