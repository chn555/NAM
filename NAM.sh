
#!/usr/bin/env bash


################################################################################
# Author :	BigRush && chn555
#
# License :  GPLv3
#
# Description :  NAM (Network Automated Manager).
#				 This script will use nmcli to set up static ip efortlessly.
#
# Version :  1.0.0
################################################################################


## Checks if the script runs as root
Root_Check () {

	if  [[ $EUID -eq 0 ]]; then
		printf "$line\n"
		printf "This option must not run with root privileges\n"
		printf "$line\n"
		exit 1
	fi
}

## Declare function’s variables, create and validate log files
Log_And_Variables () {

	####  Varibale	####
    line="\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-"
    logpath=/tmp/NAM.log
	####  Varibale	####



	## Check if log file exits, if not, create it
	if ! [[ -e $logpath ]]; then
		touch $logpath
	fi
}

## Check if kde is installed, if it is, notify the user that wireless profiles
## might not work
KDE_Check () {
  if [[ $( echo $DESKTOP_SESSION | grep plasma ) ]] ; then
    echo "NAM has detected you are using KDE,"
    echo "due to the way KDE stores wireless passwords"
    echo "the wireless profiles NAM creates might not work."
  fi
}

## Filter active network interfaces, ignoring any interfaces that are not
## ethernet or wireless
Filter_Active_Interfaces () {
  echo "Looking for active interfaces..."
  echo ""
  ## Unset Active_Interfaces array in case the array already exist
  unset Active_Interfaces
  sleep 1
  readarray -t Active_Interfaces <<< "$(nmcli -t -f NAME,UUID,TYPE,DEVICE con show --active
 )"
  for i in ${Active_Interfaces[@]}; do
      ## Filter out the real connections
      i=$(echo $i | egrep 'wireless|ethernet')
      ## Filter out the actual interface name
      i=$(echo $i | cut -d ":" -f 4)
      ## Add the names into the new array
      Filtered_Active_Interfaces+=($i)
    done
}

## If more than one exists prompt the user, if only one exists chose that one
## and notify the user, if no interfaces exist exit the program
Menu_Active_Interfaces (){
    if [[ ${#Filtered_Active_Interfaces[@]} -eq 0 ]]; then
        echo No interface is found, exiting.
            sleep 1
            ]exit 0
    elif [[ ${#Filtered_Active_Interfaces[@]} -eq 1 ]]; then
        echo Only ${Filtered_Active_Interfaces[0]} is connected, and will be used
        option=${Filtered_Active_Interfaces[0]}
        sleep 1
    else
        echo "Please select the interface you wish to use"
        arrsize=$(expr 1 + $1 )
        select option in "${@:2}"; do
            if [ "$REPLY" -eq "$arrsize" ]; then
                echo "Exiting..."
                break;
            elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $((arrsize-1)) ]; then
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

## Gather information about the interface, ip address,
## netmask(bit length format), gateway and name servers
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


## Prompt the user to enter the information. ip address, netmask,
## gateway and name servers.
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
