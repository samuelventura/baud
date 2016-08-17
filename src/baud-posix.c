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
#include "baud.h"

//not monotonic
unsigned long millis() {
  struct timeval now;
  int rv = gettimeofday(&now, NULL);
  return now.tv_sec * 1000 + now.tv_usec/1000;
}

void print_time(const char *tail) {
    struct timeval now;
    int rv = gettimeofday(&now, NULL);
    fprintf(stderr, "%d %d.%03d%s", context.pid, (int)(now.tv_sec%1000),
      (int)(now.tv_usec/1000), tail);
}

void print_last_error() {
  fprintf(stderr, "Error %d %s", errno, strerror(errno));
}

void milli_sleep(int delay) {
    usleep(delay*1000);
}

void context_init() {
  context.pid = getpid();
  context.fd = -1;
  context.bufsize = DEFAULT_BUFSIZE;
  context.portname = (char*)malloc(PORTNAME_SIZE);
  context.portname[0] = 0;
  context.infd = fileno(stdin);
  if (context.infd < 0) crash("Invalid stdin descriptor");
  context.outfd = fileno(stdout);
  if (context.outfd < 0) crash("Invalid stdout descriptor");
}

void context_cleanup() {
  if (context.resetterm) {
    if (tcsetattr(context.fd, TCSANOW, &context.old) < 0) {
      debug("Unable to restore termios");
    }
  }

  if (context.fd >= 0) {
    if (close(context.fd) < 0)
      crash("Unable to close serial %d", context.fd);
  }

  context.resetterm = false;
  context.fd = -1;
}

void serial_open(char* portname, char* baudrate, char* bitconfig) {
  if (context.fd >= 0) crash("Port already open");
  strcpy(context.portname, portname);
  char unc[32];
  snprintf(unc, sizeof(unc), "/dev/%s", context.portname);
  context.fd = open(unc, O_RDWR | O_NOCTTY);
  if (context.fd < 0)
    crash("Unable to open %s", unc);
  if (isatty(context.fd) < 0)
    crash("Device is not baud");
  if (tcgetattr(context.fd, &context.old) < 0)
    crash("Unable to get termios");
  if (tcgetattr(context.fd, &context.new) < 0)
    crash("Unable to get termios");

  context.new.c_cflag |= CLOCAL | CREAD;
  context.new.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
  context.new.c_iflag &= ~(INLCR | ICRNL); //disable 0x0D <-> 0x0A translation in Linux
  context.new.c_iflag &= ~(IXON | IXOFF | IXANY);
  context.new.c_oflag &= ~OPOST;

  //BAUDRATE
  if (strcmp(baudrate, "1200") == 0) {
    cfsetispeed(&context.new, B1200);
    cfsetospeed(&context.new, B1200);
  } else if (strcmp(baudrate, "2400") == 0) {
    cfsetispeed(&context.new, B2400);
    cfsetospeed(&context.new, B2400);
  } else if (strcmp(baudrate, "4800") == 0) {
    cfsetispeed(&context.new, B4800);
    cfsetospeed(&context.new, B4800);
  } else if (strcmp(baudrate, "9600") == 0) {
    cfsetispeed(&context.new, B9600);
    cfsetospeed(&context.new, B9600);
  } else if (strcmp(baudrate, "19200") == 0) {
    cfsetispeed(&context.new, B19200);
    cfsetospeed(&context.new, B19200);
  } else if (strcmp(baudrate, "38400") == 0) {
    cfsetispeed(&context.new, B38400);
    cfsetospeed(&context.new, B38400);
  } else if (strcmp(baudrate, "57600") == 0) {
    cfsetispeed(&context.new, B57600);
    cfsetospeed(&context.new, B57600);
  } else if (strcmp(baudrate, "115200") == 0) {
    cfsetispeed(&context.new, B115200);
    cfsetospeed(&context.new, B115200);
  } else {
    crash("Unknown baudrate %s", baudrate);
  }

  //BITCONFIG
  if (strcmp(bitconfig, "8N1") == 0) {
    context.new.c_cflag |= CS8;
    context.new.c_cflag &= ~PARENB;
    context.new.c_cflag &= ~CSTOPB;
    context.new.c_cflag &= ~CSIZE;
    context.new.c_cflag |= CS8;
  } else if (strcmp(bitconfig, "7E1") == 0) {
    context.new.c_cflag |= PARENB;
    context.new.c_cflag &= ~PARODD;
    context.new.c_cflag &= ~CSTOPB;
    context.new.c_cflag &= ~CSIZE;
    context.new.c_cflag |= CS7;
    context.new.c_iflag |= INPCK;
    context.new.c_iflag |= ISTRIP;
  } else if (strcmp(bitconfig, "7O1") == 0) {
    context.new.c_cflag |= PARENB;
    context.new.c_cflag |= PARODD;
    context.new.c_cflag &= ~CSTOPB;
    context.new.c_cflag &= ~CSIZE;
    context.new.c_cflag |= CS7;
    context.new.c_iflag |= INPCK;
    context.new.c_iflag |= ISTRIP;
  } else {
    crash("Unknown bitconfig %s", bitconfig);
  }

  //non-blocking
  context.new.c_cc[VTIME]    = 0;
  context.new.c_cc[VMIN]     = 0;

  serial_discard();

  if (tcsetattr(context.fd, TCSANOW, &context.new) < 0) crash("Unable to set termios");

  context.resetterm = true;
}

void serial_close() {
  if (context.fd < 0) crash("Invalid port id");

  if (context.resetterm) {
    if (tcsetattr(context.fd, TCSANOW, &context.old) < 0) {
      crash("Unable to restore termios");
    }
  }

  if (close(context.fd) < 0)
    crash("Unable to close serial %d", context.fd);

  context.resetterm = false;
  context.fd = -1;
}

void serial_flush() {
  if (context.fd < 0) crash("Invalid port id");
  debug("+serial flush");
  //waits until all output written to the object referred to by fd has been transmitted.
  if (tcdrain(context.fd) < 0) crash("Unable to flush serial");
}

void serial_discard() {
  if (context.fd < 0) crash("Invalid port id");
  debug("+serial discard");
  //discards data written to the object referred to by fd but not transmitted,
  //or data received but not read, depending on the value of queue_selector
  if (tcflush(context.fd, TCIOFLUSH) < 0) crash("Unable to discard");
}

void serial_set_packet_timeout(int packto) {
  if (context.fd < 0) crash("Invalid port id");

  //non-blocking
  context.new.c_cc[VTIME]    = 0;
  context.new.c_cc[VMIN]     = 0;
  if (packto > 0) {
    //unsigned char 0-255
    context.new.c_cc[VTIME]    = (unsigned char)MIN(255, packto/100);
    //unsigned char 0-255, compilers converts int to zero
    context.new.c_cc[VMIN]     = (unsigned char)MIN(255, context.bufsize);
  }
  debug("+VTIME:%d VMIN:%d", context.new.c_cc[VTIME], context.new.c_cc[VMIN]);
  if (tcsetattr(context.fd, TCSANOW, &context.new) < 0) crash("Unable to set termios");
}

int serial_available() {
  if (context.fd < 0) crash("Invalid port id");
  int count = 0;
  if (ioctl(context.fd, FIONREAD, &count) < 0) crash("Unable to peek serial");
  return count;
}

int serial_read(unsigned char* buffer, int size) {
  if (context.fd < 0) crash("Invalid port id");
  int ic = read(context.fd, buffer, size);
  phex("ser<", buffer, ic);
  return ic;
}

int serial_write(unsigned char* buffer, int size) {
  if (context.fd < 0) crash("Invalid port id");
  phex("sew>", buffer, size);
  return write(context.fd, buffer, size);
}

int stdin_available() {
  int count = 0;
  if (ioctl(context.infd, FIONREAD, &count) < 0) crash("Unable to peek stdin");
  return count;
}

int stdin_read(unsigned char* buffer, int size) {
  int ic = read(context.infd, buffer, size);
  phex("sir>", buffer, ic);
  return ic;
}

int stdout_write(unsigned char* buffer, int size) {
  phex("sow<", buffer, size);
  return write(context.outfd, buffer, size);
}

void stdout_flush() {
  debug("+stdout flush");
  if (fflush(stdout)) crash("Unable to flush stdout");
}

//no way to detect stdin is closed by polling available data
void loop(void (*loop_stdin)(void*), void (*loop_serial)(void*), void* state) {
  struct pollfd poll_fds[2];
  poll_fds[0].fd = context.infd;
  poll_fds[0].events = POLLIN;
  poll_fds[0].revents = 0;
  poll_fds[1].fd = context.fd;
  poll_fds[1].events = POLLIN;
  poll_fds[1].revents = 0;

  while(1) {
    int pc = poll(poll_fds, 2, -1);
    debug("Poll %d stdin:%d serial:%d", pc, poll_fds[0].revents, poll_fds[1].revents);
    if (pc <= 0) crash("Invalid poll return %d", pc);

    if ((poll_fds[0].revents & POLLIN) != 0) {
      poll_fds[0].revents &= ~POLLIN;
      loop_stdin(state);
    }

    if ((poll_fds[1].revents & POLLIN) != 0) {
      poll_fds[1].revents &= ~POLLIN;
      loop_serial(state);
    }

    if (poll_fds[0].revents != 0)
      crash("Unexpected stdin signal %d\n", poll_fds[0].revents);

    if (poll_fds[1].revents != 0)
      crash("Unexpected serial signal %d\n", poll_fds[1].revents);
  }
}
