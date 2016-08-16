#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include "baud.h"

struct CMD {
  char* buffer;
  int length;
  int position;
};

int stdin_read_packet(unsigned char* buffer, int size) {
  unsigned char header[2];
  int ic = stdin_read(header, 2);
  if (ic != 2) crash("Partial packet size from stdin %d", ic);
  int is = header[0]<<8 | header[1];
  if (is > size) crash("Packet larger than buffer size packet:%d buffer:%d", is, size);
  ic = stdin_read(buffer, is);
  if (is != ic) crash("Partial read from stdin expected:%d read:%d", is, ic);
  return is;
}

void stdout_write_packet(unsigned char* buffer, int size) {
  unsigned char header[2];
  header[0] = (size>>8)&0xff; header[1] = size&0xff;
  int oc = stdout_write(header, 2);
  if (2 != oc) crash("Partial header write to stdout expected:%d written:%d", 2, oc);
  oc = stdout_write(buffer, size);
  if (size != oc) crash("Partial write to stdout expected:%d written:%d", size, oc);
}

char read_char(struct CMD* cmd) {
  int start = cmd->position;
  if(cmd->position < cmd->length) {
    return cmd->buffer[cmd->position++];
  }
  crash("read_char failed at index %d", start);
  return 0;
}

int read_digit(struct CMD* cmd) {
  int start = cmd->position;
  if(cmd->position < cmd->length) {
    char c = cmd->buffer[cmd->position++];
    if (isdigit(c)) return c - '0';
  }
  crash("read_digit failed at index %d", start);
  return 0;
}

//should consume only digits and leave non digits untouch
unsigned int read_uint(struct CMD* cmd) {
  unsigned int value = 0;
  int count = 0;
  int start = cmd->position;
  while(cmd->position < cmd->length) {
    char c = cmd->buffer[cmd->position];
    if (isdigit(c)) { value *= 10; value += c - '0'; count++; cmd->position++; }
    else break;
  }
  if (count > 0) return value;
  crash("read_uint failed at index %d", start);
  return 0;
}

void read_str_n(struct CMD* cmd, int width, char* buffer, char bufsize) {
  for(int i=0; i<width; i++) {
    char c = read_char(cmd);
    if (i < bufsize - 1) { buffer[i] = c; buffer[i+1] = 0; }
    else crash("read_str_n up to '%d' failed at index %d", width, i);
  }
}

//should consume the delimiter
void read_str_c(struct CMD* cmd, char delimiter, char* buffer, char bufsize) {
  for(int i=0; ; i++) {
    char c = read_char(cmd);
    if (c == delimiter && i < bufsize) { buffer[i] = 0; return; }
    else if (c != delimiter && i < bufsize - 1) { buffer[i] = c; buffer[i+1] = 0; }
    else crash("read_str_c up to '%c' failed at index %d", delimiter, i);
  }
}

void cmd_echo(struct CMD* cmd) {
  char c = read_char(cmd);
  stdout_write_packet((unsigned char*)&c, 1);
}

void cmd_set_debug(struct CMD* cmd) {
  context.debug = read_digit(cmd);
}

void cmd_set_buffer_size(struct CMD* cmd) {
  int bufsize = read_uint(cmd);
  if (bufsize <= 0) crash("Bufsize must be positive");
  context.bufsize = bufsize;
}

void cmd_set_packet_timeout(struct CMD* cmd) {
  int packto = read_uint(cmd);
  serial_set_packet_timeout(packto);
}

void cmd_open_serial(struct CMD* cmd) {
  char baudrate[7]; //6+1
  char bitconfig[4]; //3+1
  char portname[PORTNAME_SIZE];
  read_str_c(cmd, ',', portname, PORTNAME_SIZE);
  read_str_c(cmd, ',', baudrate, sizeof(baudrate));
  read_str_n(cmd, 3, bitconfig, sizeof(bitconfig));
  serial_open(portname, baudrate, bitconfig);
}

void cmd_close_serial(struct CMD* cmd) {
  serial_close();
}

void cmd_start_loop(struct CMD* cmd) {
  int start = cmd->position;
  char c = read_char(cmd);
  switch(c) {
    case 'r':
      debug("Raw mode");
      loop_raw();
      break;
    case 't':
      debug("Text mode");
      loop_text();
      break;
    case 'g':
      debug("Modbus RTU TCP gateway mode");
      loop_modbus_rtu_tcpgw();
      break;
    case 'm':
      debug("Modbus RTU master mode");
      loop_modbus_rtu_master();
      break;
    case 's':
      debug("Modbus RTU slave mode");
      loop_modbus_rtu_slave();
      break;
    default:
    crash("cmd_start_loop invalid mode %c at index %d", c, start);
  }
}

void cmd_write(struct CMD* cmd) {
  unsigned char buffer[context.bufsize];
  int ic = stdin_read_packet(buffer, context.bufsize);
  int oc = serial_write(buffer, ic);
  if (ic != oc) crash("Partial write to serial expected:%d written:%d", ic, oc);
}

//return up to count of available data when any of the following happens:
//1) the timeout expires 2) the count is reached
void cmd_read_n_data(struct CMD* cmd) {
  int count = read_uint(cmd);
  char separator = read_char(cmd);
  int timeout = read_uint(cmd);
  if (count == 0) {
    unsigned char buffer[context.bufsize];
    int ic = serial_read(buffer, context.bufsize);
    stdout_write_packet(buffer, ic);
  } else {
      int ic = 0;
      bool done = false;
      unsigned char buffer[count];
      unsigned long dl = millis() + timeout;
      while (1) {
        while (serial_available() > 0) {
          //interchar timeout is applied despite fetching byte by byte
          //use only with packto=0 or expect length * packto delays
          ic += serial_read(buffer + ic, 1);
          if (ic >= count) done = true;
          if (done) break;
        }
        if (done) break;
        if (dl < millis()) break;
        milli_sleep(1);
      }
      stdout_write_packet(buffer, ic);
    }
}

void cmd_flush_discard_or_transmit(struct CMD* cmd) {
  int start = cmd->position;
  char c = read_char(cmd);
  switch(c) {
    case 'd':
      serial_discard();
      break;
    case 't':
      serial_flush();
      break;
    default:
    crash("cmd_flush invalid mode %c at index %d", c, start);
  }
}

void cmd_pause_millis(struct CMD* cmd) {
  int millis = read_uint(cmd);
  debug("+pause %d", millis);
  milli_sleep(millis);
}

void cmd_wait_n_data_available(struct CMD* cmd) {
  int count = read_uint(cmd);
  char separator = read_char(cmd);
  int timeout = read_uint(cmd);
  unsigned long dl = millis() + timeout;
  int available = serial_available();
  while (1) {
    if (available >= count) {
      stdout_write_packet((unsigned char*)"so", 2);
      return;
    }
    if (dl < millis()) break;
    milli_sleep(1);
    available = serial_available();
  }
  debug("+available %d", available);
  stdout_write_packet((unsigned char*)"st", 2);
}

//return whatever is available when any of the following happens:
//1) a newline is found 2) the timeout expires 3) the buffer is full
void cmd_readline(struct CMD* cmd) {
  int ic = 0;
  bool done = false;
  unsigned char buffer[context.bufsize];
  int timeout = read_uint(cmd);
  unsigned long dl = millis() + timeout;
  while (1) {
    while (serial_available() > 0) {
      //interchar timeout is applied despite fetching byte by byte
      //use only with packto=0 or expect length * packto delays
      ic += serial_read(buffer + ic, 1);
      if (buffer[ic - 1] == '\n') done = true;
      if (ic >= context.bufsize) done = true;
      if (done) break;
    }
    if (done) break;
    if (dl < millis()) break;
    milli_sleep(1);
  }
  stdout_write_packet(buffer, ic);
}

void cmd_count_available_data(struct CMD* cmd) {
  char buffer[12];
  int count = serial_available();
  int length = snprintf(buffer, sizeof(buffer), "a%d", count);
  stdout_write_packet((unsigned char*)buffer, length);
}

void cmd_modbus_rtu(struct CMD* cmd) {
  unsigned char head[4];
  unsigned char buffer[context.bufsize];
  int timeout = read_uint(cmd);
  int ic = stdin_read_packet(buffer, context.bufsize);
  if (ic < 4) crash("RTU packet too short required:%d got:%d", 4, ic);
  if (ic + 2 > context.bufsize) crash("CRC buffer overflow required:%d got:%d", ic + 2, context.bufsize);
  for(int i=0;i<4;i++) head[i] = buffer[i];
  //append modbus RTU CRC
  int crc = crc16(buffer, ic);
  buffer[ic++] = crc&0xff;
  buffer[ic++] = (crc>>8)&0xff;
  int oc = serial_write(buffer, ic);
  if (ic != oc) crash("Partial write to serial expected:%d written:%d", ic, oc);
  //wait for response
  int is = 0;
  unsigned long dl = millis() + timeout;
  while (1) {
    if (millis() > dl) {
      stdout_write_packet((unsigned char *)"me", 2);
      return;
    }
    if (serial_available() > 0) {
      is += serial_read(buffer + is, context.bufsize - is);
      if (is >= 6) {
        crc = crc16(buffer, is - 2);
        int lcrc = crc&0xff;
        int hcrc = (crc>>8)&0xff;
        if (buffer[is-2] == lcrc && buffer[is-1] == hcrc) {
          stdout_write_packet(buffer, is - 2);
          return;
        }
      }
      if (is >= context.bufsize) crash("Buffer overflow waiting RTU response %d %s", context.bufsize, tohex(buffer, is));
    }
    milli_sleep(1);
  }
}

void process_cmd(struct CMD* cmd) {
  while(cmd->position < cmd->length) {
    int start = cmd->position;
    char c = cmd->buffer[cmd->position++];
    switch(c) {
      case 'e':
        cmd_echo(cmd);
        break;
      case 'd':
        cmd_set_debug(cmd);
        break;
      case 'o':
        cmd_open_serial(cmd);
        break;
      case 'b':
        cmd_set_buffer_size(cmd);
        break;
      case 'i':
        cmd_set_packet_timeout(cmd);
        break;
      case 'l':
        cmd_start_loop(cmd);
        break;
      case 'w':
        cmd_write(cmd);
        break;
      case 'r':
        cmd_read_n_data(cmd);
        break;
      case 'n':
        cmd_readline(cmd);
        break;
      case 'a':
        cmd_count_available_data(cmd);
        break;
      case 'f':
        cmd_flush_discard_or_transmit(cmd);
        break;
      case 's':
        cmd_wait_n_data_available(cmd);
        break;
      case 'c':
        cmd_close_serial(cmd);
        break;
      case 'p':
        cmd_pause_millis(cmd);
        break;
      case 'm':
        cmd_modbus_rtu(cmd);
        break;
      default:
        crash("process_cmd failed at index %d invalid cmd %c", start, c);
    }
  }
}

int main(int argc, char *argv[]) {
  context_init();
  for(int i=1; i<argc; i++) {
    struct CMD cmd;
    char* buffer = argv[i];
    cmd.buffer = buffer;
    cmd.length = strlen(buffer);
    cmd.position = 0;
    debug("%d:%s", i, buffer);
    process_cmd(&cmd);
  }
  while(1) {
    unsigned char buffer[256];
    int ic = stdin_read_packet(buffer, sizeof(buffer));
    struct CMD cmd;
    cmd.buffer = (char*)buffer;
    cmd.length = ic;
    cmd.position = 0;
    debug(">%s", buffer);
    process_cmd(&cmd);
  }
}
