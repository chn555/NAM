#!/bin/bash
#
# written by chn555
# this script will use nmcli to set up static ip efortlessly.

# the basic command is
# nmcli con clone "chn555 5GHZ" "chn555 5GHZ static"

# nmcli con mod "chn555 5GHZ static" ipv4.method manual ipv4.addr "192.168.0.155/24" ipv4.gateway "192.168.0.1" ipv4.dns "8.8.8.8"

# Filter out the active interfaces, then keep only the ones that are real, like wireless and ethernet.
# Filter the remaining ones and extract the actual interface name

line=$(printf '%40s\n' | tr ' ' -)
echo $line
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
  # The next 2 lines are used later to validate ipv4 addresses
  oct='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
  ip4="^$oct\\.$oct\\.$oct\\.$oct$"
  # these set the default DNS, using google. yes Alex i love being spied on.
  DNS1="8.8.8.8"
  DNS2="8.8.4.4"
  echo "Please enter the information to be set."
  echo "If a field is left blank, the current setting will be used"
  sleep 1
  echo " "
  read -p "Enter desired IP address [$Ip] : " New_Ip
  if [[ $New_Ip == "" ]]; then
    New_Ip=$Ip
  else
    until [[  $New_Ip == "" ]] || [[  "$New_Ip" =~ $ip4 ]]; do
      read -p "Not a valid IP address. Re-enter [$Ip]  : " New_Ip
    done
    if [[ $New_Ip == "" ]]; then
      New_Ip=$Ip
    fi
  fi
  echo $line
  read -p "Enter desired Netmask [$Netmask] : " New_Netmask
  if [[ $New_Netmask == "" ]]; then
    New_Netmask=$Netmask
  else
    while [[ ! $New_Netmask == "" ]] && [[ ! "$New_Netmask" -gt 1  ||  ! $New_Netmask -lt 32 ]]  ; do
      read -p "Not a valid netmask, please re-enter your netmask in bit-length format [$Netmask] : " New_Netmask
    done
    if [[ $New_Netmask == "" ]]; then
      New_Netmask=$Netmask
    fi
  fi
  echo $line
  read -p "Enter desired Gateway [$Gateway] : " New_Gateway
  if [[ $New_Gateway == "" ]]; then
    New_Gateway=$Gateway
  else
    while [[ ! $New_Gateway == "" ]] && [[ ! "$New_Gateway" =~ $ip4 ]]; do
      read -p "Not a valid Gateway. Re-enter [$Gateway] :  " New_Gateway
    done
    if [[ $New_Gateway == "" ]]; then
      New_Gateway=$Gateway
    fi
  fi
  echo $line
  read -p "Enter desired primary DNS [$DNS1] : " New_DNS1
  if [[ $New_DNS1 == "" ]]; then
    New_DNS1=$DNS1
  else
    while [[ ! $New_DNS1 == "" ]] && [[ ! "$New_DNS1" =~ $ip4 ]]; do
      read -p "Not a valid DNS. Re-enter [$DNS1] :  " New_DNS1
    done
    if [[ $New_DNS1 == "" ]]; then
      New_DNS1=$DNS1
    fi
  fi
  echo $line
  read -p "Enter desired secondary DNS [$DNS2] : " New_DNS2
  if [[ $New_DNS2 == "" ]]; then
    New_DNS2=$DNS2
  else
    while [[ ! $New_DNS2 == "" ]] && [[ ! "$New_DNS2" =~ $ip4 ]]; do
      read -p "Not a valid DNS. Re-enter [$DNS2] :  " New_DNS1
    done
    if [[ $New_DNS2 == "" ]]; then
      New_DNS1=$DNS2
    fi
  fi
  Verify_Info
}

Verify_Info () {
  echo $line
  echo $line
  echo "IP address : $New_Ip/$New_Netmask"
  echo " "
  echo "Gateway : $New_Gateway"
  echo " "
  echo "Primary DNS : $New_DNS1"
  echo " "
  echo "Secondary DNS : $New_DNS2"
  echo " "
  echo " "
  Verify_Info_loop
}

Verify_Info_loop () {
  read -p "Is the information correct? [Y,n]" currect
  if [[ $currect == "" ]] || [[ $currect == "y" ]] || [[ $currect == "Y" ]]; then
    echo "Thanks for reaching the end of this script."
    echo  "as of right now it does not do anything."
    echo "If some information was incorrectly displayed, or you found a mistake, please open a new issue on https://github.com/chn555/NAM"
    :
  elif [[ $currect == "n" ]] || [[ $currect == "N" ]]; then
    echo " "
    echo $line
    echo $line
    User_Prompt
  else
    echo "Invalid input, try again"
    Verify_Info_loop
  fi
}

Clone_Profile_loop () {
  read -p "$1 already exists, override? [N,y]" Override
  if  [[ $Override == "y" ]] || [[ $Override == "Y" ]]; then
    nmcli con delete "$1"
  elif [[ $Override == "" ]] || [[ $Override == "n" ]] || [[ $Override == "N" ]]; then
    echo " "
    echo $line
    echo $line
    Profile_User_Prompt
  else
    echo "Invalid input, try again"
    Clone_Profile_loop
  fi
}

Profile_User_Prompt () {
  read -p "Enter the name of the new profile : " Temp_Profile
  nmcli con show "$Temp_Profile"  &> /dev/null
  if [[ $? == 0 ]];then
    Clone_Profile_loop "$Temp_Profile"
  else
    New_Profile=$Temp_Profile
  fi
}
Clone_Profile () {
  Active_Profile=$( nmcli --t -f NAME,UUID,TYPE,DEVICE con show --active |  grep $option |cut -d ":" -f 1 )
  New_Profile=$(echo $Active_Profile"_static")
  nmcli con show "$New_Profile" &> /dev/null
  if [[ $? == 0 ]];then
    Clone_Profile_loop "$New_Profile"
  else
    echo -e $Active_Profile "is the active profile,\nand will be cloned to" $Active_Profile"_static"
  fi
  sleep 1s
  echo "Cloning profile..."
  nmcli con clone "$Active_Profile" "$New_Profile"
  nmcli con mod "$New_Profile" ipv4.method manual ipv4.addr "$New_Ip" ipv4.gateway "$New_Gateway" ipv4.dns "$New_DNS1 $New_DNS2"
 }

Activate_New_Profile () {
  nmcli con down $Active_Profile && nmcli con up $New_Profile
  echo "Profile $New_Profile activated"
}

Filter_Active_Interfaces
Menu_Active_Interfaces "${#Filtered_Active_Interfaces[@]}" "${Filtered_Active_Interfaces[@]}"
Interface_Info
User_Prompt
Clone_Profile
Activate_New_Profile
