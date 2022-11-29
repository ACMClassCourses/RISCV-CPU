#!/bin/sh
# build testcase
./build_test.sh $@
# copy test input
if [ -f ./testspace/$@.in ]; then cp ./testspace/$@.in ./test/test.in; fi
# copy test output
if [ -f ./testspace/$@.ans ]; then cp ./testspace/$@.ans ./test/test.ans; fi
# add your own test script here
# Example:
# - iverilog/gtkwave/vivado
# - diff ./test/test.ans ./test/test.out
