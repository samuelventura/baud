#include "baud_nif.h"
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <termios.h>
#include <unistd.h>

void serial_open(BAUD_RESOURCE *res, int speed) {
  res->error = NULL;
  struct termios fdt;
  memset(&fdt, 0, sizeof(fdt));
  res->fd = -1;
  int count = snprintf(res->path, MAXPATH + 1, "/dev/%s", res->device);
  if (count <= 0 || count > MAXPATH) {
    res->error = "Path formatting failed";
    return;
  }
  res->fd = open(res->path, O_RDWR | O_NOCTTY);
  if (res->fd < 0) {
    res->error = "open failed";
    return;
  }
  if (isatty(res->fd) < 0) {
    res->error = "isatty failed";
    return;
  }
  if (tcgetattr(res->fd, &fdt) < 0) {
    res->error = "tcgetattr failed";
    return;
  }

  fdt.c_cflag |= CLOCAL | CREAD;
  fdt.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
  fdt.c_iflag &= ~(INLCR | ICRNL); // disable 0x0D <-> 0x0A translation in Linux
  fdt.c_iflag &= ~(IXON | IXOFF | IXANY);
  fdt.c_oflag &= ~OPOST;

  // BAUDRATE
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
  } else {
    res->error = "Invalid speed";
    return;
  }

  // config
  if (strcmp(res->config, "8N1") == 0) {
    fdt.c_cflag |= CS8;
    fdt.c_cflag &= ~PARENB;
    fdt.c_cflag &= ~CSTOPB;
    fdt.c_cflag &= ~CSIZE;
    fdt.c_cflag |= CS8;
  } else if (strcmp(res->config, "7E1") == 0) {
    fdt.c_cflag |= PARENB;
    fdt.c_cflag &= ~PARODD;
    fdt.c_cflag &= ~CSTOPB;
    fdt.c_cflag &= ~CSIZE;
    fdt.c_cflag |= CS7;
    fdt.c_iflag |= INPCK;
    fdt.c_iflag |= ISTRIP;
  } else if (strcmp(res->config, "7O1") == 0) {
    fdt.c_cflag |= PARENB;
    fdt.c_cflag |= PARODD;
    fdt.c_cflag &= ~CSTOPB;
    fdt.c_cflag &= ~CSIZE;
    fdt.c_cflag |= CS7;
    fdt.c_iflag |= INPCK;
    fdt.c_iflag |= ISTRIP;
  } else {
    res->error = "Invalid config";
    return;
  }

  // non-blocking
  fdt.c_cc[VTIME] = 0;
  fdt.c_cc[VMIN] = 0;

  if (tcsetattr(res->fd, TCSANOW, &fdt) < 0) {
    res->error = "tcsetattr failed";
    return;
  }
}

void serial_available(BAUD_RESOURCE *res) {
  res->error = NULL;
  size_t count = 0;
  if (ioctl(res->fd, FIONREAD, &count) < 0) {
    res->error = "ioctl failed";
    return;
  }
  res->count = count;
}

void serial_read(BAUD_RESOURCE *res, unsigned char *buffer, COUNT size) {
  res->error = NULL;
  int count = read(res->fd, buffer, size);

  if (count < 0) {
    res->error = "read failed";
    return;
  }

  if (size != count) {
    res->error = "read mismatch";
    return;
  }

  res->count = count;
}

void serial_write(BAUD_RESOURCE *res, unsigned char *buffer, COUNT size) {
  res->error = NULL;
  int count = write(res->fd, buffer, size);

  if (count < 0) {
    res->error = "write failed";
    return;
  }

  if (size != count) {
    res->error = "write mismatch";
    return;
  }

  res->count = count;
}

void serial_close(BAUD_RESOURCE *res) {
  res->error = NULL;
  int fd = res->fd;
  res->fd = -1;
  if (fd < 0) {
    res->error = "fd already closed";
    return;
  }
  if (close(fd) < 0) {
    res->error = "close failed";
    return;
  }
}
