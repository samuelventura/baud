#include "baud_nif.h"
#include <windows.h>
#include <stdio.h>

/*
https://blogs.msdn.microsoft.com/vcblog/2015/11/02/announcing-visual-c-build-tools-2015-standalone-c-tools-for-build-environments/
http://landinghub.visualstudio.com/visual-cpp-build-tools
https://www.visualstudio.com/downloads/#build-tools-for-visual-studio-2017-rc

from visualcppbuildtools_full.exe (VC++ 2015 update 3) installed Windows 8.1
SDk  C:\Program Files (x86)\Microsoft Visual C++ Build Tools

call "C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools.bat"
cd c:\Users\samuel\Documents\github\baud
https://msdn.microsoft.com/en-us/library/ff802693.aspx
*/

int serial_open(BAUD_RESOURCE *res, int speed) {

  DCB dcb;
  FillMemory(&dcb, sizeof(dcb), 0);
  res->handle = INVALID_HANDLE_VALUE;
  snprintf(res->path, MAXPATH + 1, "//./%s", res->device);
  res->handle = CreateFile(res->path, GENERIC_READ | GENERIC_WRITE, 0, 0,
                           OPEN_EXISTING, 0, 0);

  if (res->handle == INVALID_HANDLE_VALUE)
    return -1;
  if (!GetCommState(res->handle, &dcb))
    return -1;

  dcb.DCBlength = sizeof(DCB);
  dcb.fBinary = TRUE;

  // BAUDRATE
  if (speed == 1200) {
    dcb.BaudRate = CBR_1200;
  } else if (speed == 2400) {
    dcb.BaudRate = CBR_2400;
  } else if (speed == 4800) {
    dcb.BaudRate = CBR_4800;
  } else if (speed == 9600) {
    dcb.BaudRate = CBR_9600;
  } else if (speed == 14400) {
    dcb.BaudRate = CBR_14400;
  } else if (speed == 19200) {
    dcb.BaudRate = CBR_19200;
  } else if (speed == 38400) {
    dcb.BaudRate = CBR_38400;
  } else if (speed == 57600) {
    dcb.BaudRate = CBR_57600;
  } else if (speed == 115200) {
    dcb.BaudRate = CBR_115200;
  } else if (speed == 128000) {
    dcb.BaudRate = CBR_128000;
  } else if (speed == 256000) {
    dcb.BaudRate = CBR_256000;
  } else
    return -1;

  // config
  if (strcmp(res->config, "8N1") == 0) {
    dcb.ByteSize = 8;
    dcb.Parity = NOPARITY;
  } else if (strcmp(res->config, "7E1") == 0) {
    dcb.ByteSize = 7;
    dcb.Parity = EVENPARITY;
  } else if (strcmp(res->config, "7O1") == 0) {
    dcb.ByteSize = 7;
    dcb.Parity = ODDPARITY;
  } else
    return -1;

  // completely non-blocking read
  COMMTIMEOUTS ct;
  ct.ReadIntervalTimeout = MAXDWORD;
  ct.ReadTotalTimeoutConstant = 0;
  ct.ReadTotalTimeoutMultiplier = 0;
  ct.WriteTotalTimeoutConstant = 0;
  ct.WriteTotalTimeoutMultiplier = 0;

  if (!SetCommTimeouts(res->handle, &ct))
    return -1;

  if (!SetCommState(res->handle, &dcb))
    return -1;

  return 0;
}

size_t serial_available(BAUD_RESOURCE *res) {
  COMSTAT baudStat;
  if (!ClearCommError(res->handle, NULL, &baudStat))
    return -1;
  return baudStat.cbInQue;
}

size_t serial_read(BAUD_RESOURCE *res, unsigned char *buffer, int size) {
  DWORD count = 0;
  if (!ReadFile(res->handle, buffer, size, &count, NULL))
    return -1;
  return count;
}

size_t serial_write(BAUD_RESOURCE *res, unsigned char *buffer, int size) {
  DWORD count = 0;
  if (!WriteFile(res->handle, buffer, size, &count, NULL))
    return -1;
  return count;
}

int serial_close(BAUD_RESOURCE *res) {
  HANDLE handle = res->handle;
  res->handle = INVALID_HANDLE_VALUE;
  if (handle == INVALID_HANDLE_VALUE)
    return -1;
  if (!CloseHandle(handle))
    return -1;
  return 0;
}
