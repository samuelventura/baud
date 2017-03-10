#!/bin/bash -x

PROJECT="baud"
HOSTS="192.168.1.180"
FILES="lib test mix.*"

for HOST in $HOSTS; do
  ssh $HOST mkdir -p .cross/$PROJECT
  rsync -r --delete $FILES $HOST:.cross/$PROJECT/
  ssh $HOST "cd .cross/$PROJECT/ && mix deps.get && mix test"
done
