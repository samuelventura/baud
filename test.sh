#!/bin/bash -xe

case "$OSTYPE" in
  darwin*)  SOCAT_TTY=true ;; 
  linux*)   SOCAT_TTY=true ;;
  *)        SOCAT_TTY=false ;;
esac

if [[ "$SOCAT_TTY" == "true" ]]; then
  socat -d -d \
  pty,link=/tmp/tty.socat0 \
  pty,link=/tmp/tty.socat1 &

  SOCAT_PID=$!

  trap "kill -9 $SOCAT_PID" EXIT

  export TTY0="/tmp/tty.socat0"
  export TTY1="/tmp/tty.socat1"

  mix test "$@"
fi
