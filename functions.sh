#!/bin/bash
#
# written by chn555
# this script will use nmcli to set up static ip efortlessly.

# the basic command is
# nmcli con clone "chn555 5GHZ" "chn555 5GHZ static"

# nmcli con mod "chn555 5GHZ static" ipv4.method manual ipv4.addr "192.168.0.155/24" ipv4.gateway "192.168.0.1" ipv4.dns "8.8.8.8"


Filter_Active_Interfaces () {
  Active_Interfaces=($(nmcli -t con show --active | cut -d ":" -f 4))
  echo ${Active_Interfaces[*]}
}

Menu_Active_Interfaces (){
  arrsize=$(expr 1 + $1 )
  echo "Size of array: $arrsize"
  echo "${@:2}"
  select option in "${@:2}"; do
    if [ "$REPLY" -eq "$arrsize" ];
    then
      echo "Exiting..."
      break;
    elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $((arrsize-1)) ];
    then
      echo "You selected $option which is option $REPLY"
      break;
    else
      echo "Incorrect Input: Select a number 1-$arrsize"
    fi
  done
}

Interface_IP () {
    declare IP=$(ip addr show $option | awk '{if(NR==3) print $2}' )
    echo $IP
    Netmask=$(echo $IP | cut -d "/" -f "2")
}

Clone_Profile () {
  Active_Profile=$( nmcli -t con show --active |  awk '{if(NR==1) print $0}'|cut -d ":" -f 1 )
  echo -e $Active_Profile "is the active profile,\nand will be cloned to" $Active_Profile"static"
}

IP_Addr_Prompt () {}

Filter_Active_Interfaces
Menu_Active_Interfaces "${#Active_Interfaces[@]}" "${Active_Interfaces[@]}"
Interface_IP
Clone_Profile
