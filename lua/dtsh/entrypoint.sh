#!/bin/bash
#set -x
#******************************************************************************
# @file    : entrypoint.sh
# @author  : wangyubin
# @date    : 2018-08- 1 10:18:43
#
# @brief   : entry point for manage service start order
# history  : init
#******************************************************************************

: ${SLEEP_SECOND:=3}

wait_for() {
    echo Waiting for $1 to listen on $2...
    #while ! nc -z $1 $2; do echo waiting...; sleep $SLEEP_SECOND; done
    result=`echo “”|telnet $1 $2|grep Connected|wc -l`
    while [ $result -eq 0 ]
    do 
      echo waiting for $1 to listen on $2...
      sleep $SLEEP_SECOND
      result=`echo “”|telnet $1 $2|grep Connected|wc -l`
      echo $result
    done

    echo ip $1 with port on $2 has ready!
}

declare DEPENDS
declare CMD

while getopts "d:c:" arg
do
    case $arg in
        d)
            DEPENDS=$OPTARG
            ;;
        c)
            CMD=$OPTARG
            ;;
        ?)
            echo "unkonw argument"
            exit 1
            ;;
    esac
done

for var in ${DEPENDS//,/ }
do
    host=${var%:*}
    port=${var#*:}
    echo $host
    echo $port
    wait_for $host $port
done

echo will exec $CMD

eval $CMD

echo $CMD exec finished