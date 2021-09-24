dir=`dirname $0`
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/tmp/usr/local/lib
$dir/ctrl $@
