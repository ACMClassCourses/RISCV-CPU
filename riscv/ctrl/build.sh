set -e
dir=`dirname $0`
g++ $dir/controller.cpp -std=c++14 -I /tmp/usr/local/include/ -L /tmp/usr/local/lib/ -lserial -lpthread -o $dir/ctrl
