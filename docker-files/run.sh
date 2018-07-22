#!/bin/sh

cd /app
git pull > /dev/null
bundle > /dev/null

echo "Starting forever-internets..."
echo "Router Plug IP: $ROUTER_PLUG_IP, Modem Plug IP: $MODEM_PLUG_IP"
./forever-internets -r $ROUTER_PLUG_IP -m $MODEM_PLUG_IP
