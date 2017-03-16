#!/bin/bash -x

PROJECT="baud"
HOSTS="192.168.1.180 192.168.1.181"
FILES="lib test mix.* *.sh"
SCRIPT=`realpath $0`

remote() {
  chmod a+x "$SCRIPT"
  for HOST in $HOSTS; do
    ssh $HOST mkdir -p .farm/$PROJECT
    rsync -rp --delete $FILES $HOST:.farm/$PROJECT/
    #sourcing farm won't work
    ssh $HOST ".farm/$PROJECT/farm.sh local"
  done
}

local() {
  MIX="`which mix`"
  if [ "$(expr substr $(uname -s) 1 9)" == "CYGWIN_NT" ]; then
    MIX="$MIX.bat"
  fi
  cd `dirname "$SCRIPT"`
  #mix local.hex --force
  "$MIX" deps.get
  "$MIX" test
}

$@
