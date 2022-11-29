#!/bin/sh
# build testcase
./build_test.sh $@
# copy test input
if [ -f ./testspace/$@.in ]; then cp ./testspace/$@.in ./test/test.in; fi
# copy test output
if [ -f ./testspace/$@.ans ]; then cp ./testspace/$@.ans ./test/test.ans; fi
# add your own test script here
# Example: assuming serial port on /dev/ttyUSB1
./ctrl/build.sh
./ctrl/run.sh ./test/test.bin ./test/test.in /dev/ttyUSB1 -I
#./ctrl/run.sh ./test/test.bin ./test/test.in /dev/ttyUSB1 -T > ./test/test.out
#if [ -f ./test/test.ans ]; then diff ./test/test.ans ./test/test.out; fi
