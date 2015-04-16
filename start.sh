#!/bin/bash

PRIVATE_IP=$(ifconfig eth0 | grep "inet " | awk '{print $2}' | cut -d ':' -f 2)

echo "-name syncex@$PRIVATE_IP" >> vm.args
echo "-setcookie $COOKIE" >> vm.args

export VMARGS_PATH=$(pwd)/vm.args

exec rel/syncex/bin/syncex foreground
