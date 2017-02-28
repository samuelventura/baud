#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <termios.h>
#include <stdarg.h>
#include <stdio.h>
#include <unistd.h>
#include <poll.h>
#include <errno.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include "baud_nif.h"

int serial_open(BAUD_RESOURCE* res, char* device, int speed, char* config) {

  struct termios fdt;
  res->fd = -1;
  res->fd = open(device, O_RDWR | O_NOCTTY);

  if (res->fd < 0) return -1;
  if (isatty(res->fd) < 0) return -1;
  if (tcgetattr(res->fd, &fdt) < 0) return -1;

  fdt.c_cflag |= CLOCAL | CREAD;
  fdt.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
  fdt.c_iflag &= ~(INLCR | ICRNL); //disable 0x0D <-> 0x0A translation in Linux
  fdt.c_iflag &= ~(IXON | IXOFF | IXANY);
  fdt.c_oflag &= ~OPOST;

  //BAUDRATE
  if (speed == 1200) {
    cfsetispeed(&fdt, B1200);
    cfsetospeed(&fdt, B1200);
  } else if (speed == 2400) {
    cfsetispeed(&fdt, B2400);
    cfsetospeed(&fdt, B2400);
  } else if (speed == 4800) {
    cfsetispeed(&fdt, B4800);
    cfsetospeed(&fdt, B4800);
  } else if (speed == 9600) {
    cfsetispeed(&fdt, B9600);
    cfsetospeed(&fdt, B9600);
  } else if (speed == 19200) {
    cfsetispeed(&fdt, B19200);
    cfsetospeed(&fdt, B19200);
  } else if (speed == 38400) {
    cfsetispeed(&fdt, B38400);
    cfsetospeed(&fdt, B38400);
  } else if (speed == 57600) {
    cfsetispeed(&fdt, B57600);
    cfsetospeed(&fdt, B57600);
  } else if (speed == 115200) {
    cfsetispeed(&fdt, B115200);
    cfsetospeed(&fdt, B115200);
  } else return -1;

  //config
  if (strcmp(config, "8N1") == 0) {
    fdt.c_cflag |= CS8;
    fdt.c_cflag &= ~PARENB;
    fdt.c_cflag &= ~CSTOPB;
    fdt.c_cflag &= ~CSIZE;
    fdt.c_cflag |= CS8;
  } else if (strcmp(config, "7E1") == 0) {
    fdt.c_cflag |= PARENB;
    fdt.c_cflag &= ~PARODD;
    fdt.c_cflag &= ~CSTOPB;
    fdt.c_cflag &= ~CSIZE;
    fdt.c_cflag |= CS7;
    fdt.c_iflag |= INPCK;
    fdt.c_iflag |= ISTRIP;
  } else if (strcmp(config, "7O1") == 0) {
    fdt.c_cflag |= PARENB;
    fdt.c_cflag |= PARODD;
    fdt.c_cflag &= ~CSTOPB;
    fdt.c_cflag &= ~CSIZE;
    fdt.c_cflag |= CS7;
    fdt.c_iflag |= INPCK;
    fdt.c_iflag |= ISTRIP;
  } else return -1;

  //non-blocking
  fdt.c_cc[VTIME] = 0;
  fdt.c_cc[VMIN]  = 0;

  if (tcsetattr(res->fd, TCSANOW, &fdt) < 0) return -1;

  return 0;
}

size_t serial_available(BAUD_RESOURCE* res) {
  size_t count = 0;
  if (ioctl(res->fd, FIONREAD, &count) < 0) return -1;
  return count;
}

size_t serial_read(BAUD_RESOURCE* res, unsigned char* buffer, int size) {
  return read(res->fd, buffer, size);
}

size_t serial_write(BAUD_RESOURCE* res, unsigned char* buffer, int size) {
  return write(res->fd, buffer, size);
}

int serial_close(BAUD_RESOURCE* res) {
  int fd = res->fd;
  res->fd = -1;
  if (fd < 0) return -1;
  if (close(fd) < 0) return -1;
  return 0;
}
