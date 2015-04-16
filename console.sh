#!/bin/bash

PRIVATE_IP=$(ifconfig eth0 | grep "inet " | awk '{print $2}' | cut -d ':' -f 2)

iex --name client@$PRIVATE_IP --cookie $COOKIE -e "Node.ping(:\"syncex@$SYNCEX_PORT_4369_TCP_ADDR\")"
