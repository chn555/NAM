#!/bin/bash
#
# written by chn555
# this script will use nmcli to set up static ip efortlessly.

# the basic command is
# nmcli con clone "chn555 5GHZ" "chn555 5GHZ static"

# nmcli con mod "chn555 5GHZ static" ipv4.method manual ipv4.addr "192.168.0.155/24" ipv4.gateway "192.168.0.1" ipv4.dns "8.8.8.8"

# Filter out the active interfaces, then keep only the ones that are real, like wireless and ethernet.
# Filter the remaining ones and extract the actual interface name
Filter_Active_Interfaces () {
  echo Looking for active interfaces...
  echo ""
  sleep 1
  readarray -t Active_Interfaces <<< "$(nmcli -t -f NAME,UUID,TYPE,DEVICE con show --active
 )"
  for i in ${Active_Interfaces[@]}; do
      # Filter out the real connections
      i=$(echo $i | egrep 'wireless|ethernet')
      # Filter out the actual interface name
      i=$(echo $i | cut -d ":" -f 4)
      # Add the names into the new array
      Filtered_Active_Interfaces+=($i)
    done
}

Menu_Active_Interfaces (){
  # IF there are no active interfaces, exit
  # IF only one active interface, select it
  # ELSE prompt user for the right interface
  if [[ ${#Filtered_Active_Interfaces[@]} -eq 0 ]]; then
     echo No interface is found, exiting.
     sleep 1
     exit 0
  elif [[ ${#Filtered_Active_Interfaces[@]} -eq 1 ]]; then
    echo Only ${Filtered_Active_Interfaces[0]} is connected, and will be used
     option=${Filtered_Active_Interfaces[0]}
     sleep 1
  else
    echo "Please select the interface you wish to use"
    arrsize=$(expr 1 + $1 )
    select option in "${@:2}"; do
      if [ "$REPLY" -eq "$arrsize" ];
      then
        echo "Exiting..."
        break;
      elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $((arrsize-1)) ];
      then
        echo "You selected $option which is option $REPLY"
        sleep 1
        echo ""
        break;
      else
        echo "Incorrect Input: Select a number 1-$arrsize"
      fi
    done
  fi
}

Interface_Info () {
    echo "Gathering information..."
    echo ""
    sleep 1
    # Extract ip, netmask and gateway
    declare Ip_Info=$(ip addr show $option | awk '{if(NR==3) print $2}')
    Ip=$(ip addr show $option | awk '{if(NR==3) print $2}' |cut -d "/" -f "1")
    Netmask=$(echo $Ip_Info | cut -d "/" -f "2")
    Gateway=$(ip route show  | awk 'NR==1 {print $3}')
}

User_Prompt () {
  echo "Please enter the information to be set."
  echo "If a field is left blank, the current setting will be used"
  sleep 1
  echo " "
  read -p "Enter desired IP address [$Ip] : " New_Ip
  if [[ $New_Ip == "" ]]; then
    New_Ip=$Ip
  elif ! [[ $New_Ip =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$  ]]; then
    echo "Invalid IP address, please try again"
    read -p "Enter desired IP address [$Ip] : " New_Ip
  else
    :
  fi
  echo $New_Ip
  read -p "Enter desired Netmask [$Netmask] : " New_Netmask
  if [[ $New_Netmask == "" ]]; then
    New_Netmask=$Netmask
  else
    :
  fi
  echo $New_Netmask
  read -p "Enter desired Gateway [$Gateway] : " New_Gateway
  if [[ $New_Gateway == "" ]]; then
    New_Gateway=$Gateway
  else
    :
  fi
  echo $New_Gateway
}

Clone_Profile () {
  Active_Profile=$( nmcli --t -f NAME,UUID,TYPE,DEVICE con show --active |  awk '{if(NR==1) print $0}'|cut -d ":" -f 1 )
  echo -e $Active_Profile "is the active profile,\nand will be cloned to" $Active_Profile"static"
}

#IP_Addr_Prompt () {}

Filter_Active_Interfaces
Menu_Active_Interfaces "${#Filtered_Active_Interfaces[@]}" "${Filtered_Active_Interfaces[@]}"
Interface_Info
User_Prompt
#Clone_Profile
