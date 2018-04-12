#!/bin/bash
#
# written by chn555
# this script will use nmcli to set up static ip efortlessly.

# the basic command is
# nmcli con clone "chn555 5GHZ" "chn555 5GHZ static"

# nmcli con mod "chn555 5GHZ static" ipv4.method manual ipv4.addr "192.168.0.155/24" ipv4.gateway "192.168.0.1" ipv4.dns "8.8.8.8"
