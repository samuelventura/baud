#include <windows.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include "baud.h"

//not monotonic
unsigned long millis() {
  SYSTEMTIME now;
  GetSystemTime(&now);
  return now.wSecond * 1000 + now.wMilliseconds;
}

void print_time(const char *tail) {
  SYSTEMTIME now;
  GetSystemTime(&now);
  fprintf(stderr, "%d %d.%03d%s", context.pid, now.wSecond,
      now.wMilliseconds, tail);
}

void print_last_error() {
  fprintf(stderr, "Error le:%d %d %s", errno, strerror(errno), GetLastError());
}

void milli_sleep(int delay) {
    Sleep(delay);
}

void context_init() {
  context.pid = GetCurrentProcessId();
  context.fd = INVALID_HANDLE_VALUE;
  context.bufsize = DEFAULT_BUFSIZE;
  context.portname = (char*)malloc(PORTNAME_SIZE);
  context.portname[0] = 0;
  ZeroMemory(&context.old, sizeof(context.old));
  ZeroMemory(&context.new, sizeof(context.new));
  context.old.DCBlength = sizeof(context.old);
  context.new.DCBlength = sizeof(context.new);
  context.infd = GetStdHandle(STD_INPUT_HANDLE);
  context.outfd = GetStdHandle(STD_OUTPUT_HANDLE);
  if(context.infd == INVALID_HANDLE_VALUE)
    crash("Invalid stdin handle");
  if(context.outfd == INVALID_HANDLE_VALUE)
    crash("Invalid stdout handle");
}

void context_cleanup() {
  if (context.resetterm) {
    if(!SetCommState(context.fd, &context.old)) {
      debug("Unable to restore termios");
    }
  }

  if (context.fd != INVALID_HANDLE_VALUE) {
    if (!CloseHandle(context.fd))
      debug("Unable to close serial %d", context.fd);
  }

  context.resetterm = false;
  context.fd = INVALID_HANDLE_VALUE;
}

void serial_open(char* portname, char* baudrate, char* bitconfig) {
  if (context.fd != INVALID_HANDLE_VALUE)  crash("Port already open");
  strcpy(context.portname, portname);
  char unc[32];
  snprintf(unc, sizeof(unc), "//./%s", context.portname);
  context.fd = CreateFile(unc, GENERIC_READ | GENERIC_WRITE, 0, 0, OPEN_EXISTING, 0, 0);
  if (context.fd == INVALID_HANDLE_VALUE)
    crash("Unable to open %s", unc);

  if (!GetCommState(context.fd, &context.old))
    crash("Unable to get termios");
  if (!GetCommState(context.fd, &context.new))
    crash("Unable to get termios");

  //BAUDRATE
  if (strcmp(baudrate, "1200") == 0) {
    context.new.BaudRate = CBR_1200;
  } else if (strcmp(baudrate, "2400") == 0) {
    context.new.BaudRate = CBR_2400;
  } else if (strcmp(baudrate, "4800") == 0) {
    context.new.BaudRate = CBR_4800;
  } else if (strcmp(baudrate, "9600") == 0) {
    context.new.BaudRate = CBR_9600;
  } else if (strcmp(baudrate, "19200") == 0) {
    context.new.BaudRate = CBR_19200;
  } else if (strcmp(baudrate, "38400") == 0) {
    context.new.BaudRate = CBR_38400;
  } else if (strcmp(baudrate, "57600") == 0) {
    context.new.BaudRate = CBR_57600;
  } else if (strcmp(baudrate, "115200") == 0) {
    context.new.BaudRate = CBR_115200;
  } else {
    crash("Unknown baudrate %s", baudrate);
  }

  //BITCONFIG
  context.new.StopBits = ONESTOPBIT;
  if (strcmp(bitconfig, "8N1") == 0) {
    context.new.ByteSize = 8;
    context.new.Parity = NOPARITY;
  } else if (strcmp(bitconfig, "7E1") == 0) {
    context.new.ByteSize = 7;
    context.new.Parity = EVENPARITY;
  } else if (strcmp(bitconfig, "7O1") == 0) {
    context.new.ByteSize = 7;
    context.new.Parity = ODDPARITY;
  } else {
    crash("Unknown bitconfig %s", bitconfig);
  }

  //completely non-blocking read
  COMMTIMEOUTS ct;
  ct.ReadIntervalTimeout = MAXDWORD;
  ct.ReadTotalTimeoutConstant = 0;
  ct.ReadTotalTimeoutMultiplier = 0;
  ct.WriteTotalTimeoutConstant = 0;
  ct.WriteTotalTimeoutMultiplier = 0;

  //prevent ReadFile blocking until buffer is filled
  if (!SetCommTimeouts(context.fd, &ct))
    crash("Unable to set timeouts");

  serial_discard();

  if(!SetCommState(context.fd, &context.new))
    crash("Unable to set termios");

  context.resetterm = true;
}

void serial_close() {
  if (context.fd == INVALID_HANDLE_VALUE)  crash("Invalid port id");

  if (context.resetterm) {
    if(!SetCommState(context.fd, &context.old)) {
      crash("Unable to restore termios");
    }
  }

  if (!CloseHandle(context.fd))
    crash("Unable to close serial %d", context.fd);

  context.resetterm = false;
  context.fd = INVALID_HANDLE_VALUE;
}

void serial_flush() {
  if (context.fd == INVALID_HANDLE_VALUE)  crash("Invalid port id");
  debug("+serial flush");
  //writes all the buffered information for a specified file to the device or pipe
  if (!FlushFileBuffers(context.fd)) crash("Unable to flush serial");
}

void serial_discard() {
  if (context.fd == INVALID_HANDLE_VALUE)  crash("Invalid port id");
  debug("+serial discard");
  //Discards all characters from the output or input buffer
  if (!PurgeComm(context.fd, PURGE_RXCLEAR | PURGE_TXCLEAR))
    crash("Unable to discard serial");
}

void serial_set_packet_timeout(int packto) {
  if (context.fd == INVALID_HANDLE_VALUE) crash("Invalid port id");

  //completely non-blocking read
  COMMTIMEOUTS ct;
  ct.ReadIntervalTimeout = MAXDWORD;
  ct.ReadTotalTimeoutConstant = 0;
  ct.ReadTotalTimeoutMultiplier = 0;
  ct.WriteTotalTimeoutConstant = 0;
  ct.WriteTotalTimeoutMultiplier = 0;

  if (packto > 0) {
    ct.ReadIntervalTimeout = packto;
  }
  debug("+ReadIntervalTimeout:%d", ct.ReadIntervalTimeout);

  if (!SetCommTimeouts(context.fd, &ct))
    crash("Unable to set timeouts");
}

int serial_available() {
  if (context.fd == INVALID_HANDLE_VALUE)  crash("Invalid port id");
  COMSTAT baudStat;
  if (!ClearCommError(context.fd, NULL, &baudStat)) crash("Error peeking baud");
  return baudStat.cbInQue;
}

int serial_read(unsigned char* buffer, int size) {
  if (context.fd == INVALID_HANDLE_VALUE)  crash("Invalid port id");
  DWORD count = 0;
  if(!ReadFile(context.fd, buffer, size, &count, NULL)) return -1;
  phex("ser<", buffer, count);
  return count;
}

int serial_write(unsigned char* buffer, int size) {
  if (context.fd == INVALID_HANDLE_VALUE)  crash("Invalid port id");
  DWORD count = 0;
  phex("sew>", buffer, size);
  if(!WriteFile(context.fd, buffer, size, &count, NULL)) return -1;
  return count;
}

int stdin_available() {
  DWORD stdinBytes = 0;
  if (!PeekNamedPipe(context.infd, NULL, 0, NULL, &stdinBytes, NULL)) crash("Error peeking stdin");
  return stdinBytes;
}

int stdin_read(unsigned char* buffer, int size) {
  DWORD count = 0;
  if(!ReadFile(context.infd, buffer, size, &count, NULL)) return -1;
  phex("sir>", buffer, count);
  return count;
}

int stdout_write(unsigned char* buffer, int size) {
  DWORD count = 0;
  phex("sow<", buffer, size);
  if(!WriteFile(context.outfd, buffer, size, &count, NULL)) return -1;
  return count;
}

void stdout_flush() {
  debug("+stdout flush");
  if (fflush(stdout)) crash("Unable to flush stdout");
}

void loop(void (*loop_stdin)(void*), void (*loop_serial)(void*), void* state) {
  while(1) {
    if (stdin_available() > 0) {
      loop_stdin(state);
    }
    if (serial_available() > 0) {
      loop_serial(state);
    }
    milli_sleep(1);
  }
}
