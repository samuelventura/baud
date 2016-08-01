#include <stdlib.h>
#include "baud.h"

void loop_raw() {
  struct RAW raw;
  unsigned char array1[context.bufsize];
  raw.buffer.array = array1;
  raw.buffer.size = context.bufsize;
  loop(loop_stdin_raw, loop_serial_raw, &raw);
}

void loop_text() {
  struct TEXT text;
  unsigned char array1[context.bufsize];
  unsigned char array2[context.bufsize];
  text.input.array = array1;
  text.input.size = context.bufsize;
  text.line.array = array2;
  text.line.size = context.bufsize;
  text.packCount = 0;
  loop(loop_stdin_text, loop_serial_text, &text);
}

void loop_modbus() {
  struct MODBUS modbus;
  unsigned char array1[context.bufsize];
  unsigned char array2[context.bufsize];
  modbus.input.array = array1;
  modbus.input.size = context.bufsize;
  modbus.serial.array = array2;
  modbus.serial.size = context.bufsize;
  modbus.packCount = -1;
  loop(loop_stdin_modbus, loop_serial_modbus, &modbus);
}

void loop_stdin_raw(void* state) {
  struct RAW *raw = (struct RAW*)state;
  int ic = stdin_read_packet(raw->buffer.array, raw->buffer.size);
  int oc = serial_write(raw->buffer.array, ic);
  if (ic != oc) crash("Partial write to serial expected:%d written:%d", ic, oc);
}

void loop_serial_raw(void* state) {
  struct RAW *raw = (struct RAW*)state;
  int ic = serial_read(raw->buffer.array, raw->buffer.size);
  stdout_write_packet(raw->buffer.array, ic);
}

void loop_stdin_text(void* state) {
  struct TEXT *text = (struct TEXT*)state;
  int ic = stdin_read_packet(text->input.array, text->input.size);
  int oc = serial_write(text->input.array, ic);
  if (ic != oc) crash("Partial write to serial expected:%d written:%d", ic, oc);
}

void loop_serial_text(void* state) {
  struct TEXT *text = (struct TEXT*)state;
  int ic = serial_read(text->input.array, text->input.size);
  for(int i=0; i<ic; i++) {
    unsigned char b = text->input.array[i];
    text->line.array[text->packCount++] = b;
    if (b == '\n') {
      stdout_write_packet(text->line.array, text->packCount);
      text->packCount = 0;
    }
    else if (text->packCount >= text->line.size) crash("Line buffer overflow reading serial processed:%d(%s) pending:%d(%s)",
      text->packCount, tohex(text->line.array, text->packCount), ic - i - 1, tohex(text->input.array + i + 1, ic - i - 1));
  }
}

void loop_stdin_modbus(void* state) {
  struct MODBUS *modbus = (struct MODBUS*)state;
  int ic = stdin_read_packet(modbus->input.array, modbus->input.size);
  //calculate modbus tcp packet size
  int is = (modbus->input.array[4]<<8 | modbus->input.array[5]) + 6;
  if (is != ic) crash("Invalid modbus tcp from stdin expected:%d read:%d", is, ic);
  if (ic + 2 > modbus->input.size) crash("CRC buffer overflow required:%d got:%d", ic + 2, modbus->input.size);
  //append modbus RTU CRC
  int crc = crc16(modbus->input.array + 6, ic - 6);
  modbus->input.array[ic] = crc&0xff;
  modbus->input.array[ic + 1] = (crc>>8)&0xff;
  is = ic - 6 + 2; //modbus rtu packet size
  //enable and/or resets response
  modbus->packCount = 0;
  int oc = serial_write(modbus->input.array + 6, is);
  if (is != oc) crash("Partial write to serial expected:%d written:%d", is, oc);
}

void loop_serial_modbus(void* state) {
  struct MODBUS *modbus = (struct MODBUS*)state;
  int ic = serial_read(modbus->serial.array, modbus->serial.size);
  //discard data if no pending response
  if (modbus->packCount >= 0) {
    for(int i=0; i<ic; i++) {
      unsigned char b = modbus->serial.array[i];
      modbus->input.array[6 + modbus->packCount++] = b;
      unsigned short crc = modbus->input.array[modbus->packCount + 6 - 1]<<8 | modbus->input.array[modbus->packCount + 6 - 2];
      // slave(1)+funct(1)+addr(2)+crc(2) = 6 as minimum rtu response size
      if (modbus->packCount >=6 && crc == crc16(modbus->input.array + 6, modbus->packCount - 2)) {
        modbus->packCount -= 2;
        modbus->input.array[4] = (modbus->packCount>>8)&0xff;
        modbus->input.array[5] = modbus->packCount&0xff;
        modbus->packCount += 6;
        stdout_write_packet(modbus->input.array, modbus->packCount);
        if (ic - i - 1 > 0) crash("Extra bytes from serial processed:%d(%s) pending:%d(%s)",
          modbus->packCount, tohex(modbus->input.array, modbus->packCount), ic - i - 1, tohex(modbus->serial.array + i + 1, ic - i - 1));
        //disable packed processing from serial
        modbus->packCount = -1;
      }
      else if (modbus->packCount + 6 >= modbus->input.size) crash("Packet buffer overflow reading serial processed:%d(%s) pending:%d(%s)",
        modbus->packCount, tohex(modbus->input.array, modbus->packCount), ic - i - 1, tohex(modbus->serial.array + i + 1, ic - i - 1));
    }
  } else crash("Discarding bytes from serial: %d(%s)", ic, tohex(modbus->serial.array, ic));
}
