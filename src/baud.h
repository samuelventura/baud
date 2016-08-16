#ifndef _BAUD_H_
#define _BAUD_H_

#define PORTNAME_SIZE 32
#define DEFAULT_BUFSIZE 255
#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y));
#define MAX(X, Y) (((X) > (Y)) ? (X) : (Y));
typedef unsigned int bool;
#define false 0
#define true 1
#define force_debug false

#ifdef _WIN32
#include <windows.h>
#else
#include <termios.h>
#endif

struct CONTEXT {
  int    pid;                 //process id
  char*  portname;            //name of the port
  bool   debug;               //should log to stderr?
  bool   resetterm;           //should reset term?
  int    bufsize;             //buffer size
#ifdef _WIN32
  HANDLE fd;                  //baud handle
  HANDLE infd;                //stdin handle
  HANDLE outfd;               //stdin handle
  DCB    old;                 //save termios
  DCB    new;                 //used termios
#else
  int    fd;                  //baud file descriptor
  int    infd;                //stdin file descriptor
  int    outfd;               //stdout file descriptor
  struct termios old;         //save termios
  struct termios new;         //used termios
#endif
} context;

struct BUFFER {
  unsigned char *array;
  int size;
};

struct RAW {
  unsigned char *header;
  struct BUFFER buffer;
};

struct TEXT {
  unsigned char *header;
  struct BUFFER input;
  struct BUFFER line;
  int packCount;
};

struct MODBUS {
  unsigned char *header;
  struct BUFFER input;
  struct BUFFER serial;
  int packCount;
};

//utils.c
void debug(const char* fmt, ...);
void crash(const char* fmt, ...);
void phex(const char *header, unsigned char *buf, int size);
char* tohex(unsigned char *buf, int size);
unsigned short crc16(unsigned char *buf, int len);

//baud-{msys2|posix}.c
unsigned long millis();
void milli_sleep(int delay);
void print_time(const char *tail);
void print_last_error();

void context_init();
void context_cleanup();

void serial_open(char* portname, char* baudrate, char* bitconfig);
void serial_close();
void serial_set_packet_timeout(int packto);
int serial_read(unsigned char* buffer, int size);
int serial_write(unsigned char* buffer, int size);
int serial_available();
void serial_discard();
void serial_flush();
int stdin_read(unsigned char* buffer, int size);
int stdin_read_packet(unsigned char* buffer, int size);
int stdin_available();
int stdout_write(unsigned char* buffer, int size);
void stdout_write_packet(unsigned char* buffer, int size);
void stdout_flush();

void loop(void (*on_stdin)(void*), void (*on_serial)(void*), void* state);
void loop_raw();
void loop_text();
void loop_modbus_rtu_tcpgw();
void loop_modbus_rtu_master();
void loop_modbus_rtu_slave();
void loop_stdin_raw(void* state);
void loop_serial_raw(void* state);
void loop_stdin_text(void* state);
void loop_serial_text(void* state);
void loop_stdin_rtu_tcpgw(void* state);
void loop_serial_rtu_tcpgw(void* state);
void loop_stdin_rtu_master(void* state);
void loop_serial_rtu_master(void* state);
void loop_stdin_rtu_slave(void* state);
void loop_serial_rtu_slave(void* state);

#endif
