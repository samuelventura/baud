#!/bin/bash

#isolate test run
for test in test/*_test.exs
do
 mix test $test
done
#check no zombie is left behind
ps -A | grep baud
