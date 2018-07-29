
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
	line=$(printf '%40s\n' | tr ' ' -)
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
		echo $line
    echo "NAM has detected you are using KDE,"
    echo "due to the way KDE stores wireless passwords"
    echo "the wireless profiles NAM will require you to enter the password."
		echo $line
		echo ""
		sleep 3s
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
  readarray -t Active_Interfaces <<< "$(nmcli -t -f NAME,UUID,TYPE,DEVICE con show --active)"
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
Active_Interfaces_Menu (){
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
        arrsize=$(expr 1 + $1)
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
}


## This function displays the user input to the user,
## asks the user to verify the information
Verify_Info () {
  echo $line
  echo ""
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
  read -p "Is the information correct? [Y,n]" currect
  until [[ $currect == "" ]] || [[ $currect == "y" ]] ||\
  [[ $currect == "Y" ]] || [[ $currect == "n" ]] || \
  [[ $currect == "N" ]]; do
	echo "Invalid input, try again"
	read -p "Is the information correct? [Y,n]" currect
  done

  if [[ $currect == "" ]] || [[ $currect == "y" ]] || [[ $currect == "Y" ]]; then
    :

  elif [[ $currect == "n" ]] || [[ $currect == "N" ]]; then
    echo " "
    echo $line
    echo $line
    User_Prompt
  fi
}


## This function asks the user for the new profile name,
## if the name is used already it will run the Overwrite_Profile_Loop,
## otherwise it will continue will the entered name.
Profile_Prompt () {
	echo $line
	while [[ $Temp_Profile == "" ]]; do
  	read -p "Enter the name of the new profile : " Temp_Profile
	done
  nmcli con show "$Temp_Profile"  &> $logpath
  if [[ $? == 0 ]];then
    Overwrite_Profile_Prompt "$Temp_Profile"
  else
    New_Profile=$Temp_Profile
  fi
}


## This function will only be used if the user has entered a profile name that is in use.
## The function will notify him the name is in use and ask him to overwrite the existing profile.
Overwrite_Profile_Prompt () {
  read -p "$1 already exists, override? [N,y]" Override
  if  [[ $Override == "y" ]] || [[ $Override == "Y" ]]; then
    nmcli con delete "$1" &> $logpath
  elif [[ $Override == "" ]] || [[ $Override == "n" ]] || [[ $Override == "N" ]]; then
    echo " "
    echo $line
    echo $line
    Profil_Prompt
  else
    echo "Invalid input, try again"
    Overwrite_Profile_Prompt
  fi
}


## This function obtains the name of the active profile,
## clones it to the new name and modifies it to the use the user input.
Clone_Profile () {
  Active_Profile=$( nmcli --t -f NAME,UUID,TYPE,DEVICE con show --active |  grep $option |cut -d ":" -f 1 )
  sleep 1s
  echo "Cloning profile..."
  nmcli con clone "$Active_Profile" "$New_Profile" &> $logpath
  nmcli con mod "$New_Profile" ipv4.method manual ipv4.addr "$New_Ip/$New_Netmask" ipv4.gateway "$New_Gateway" ipv4.dns "$New_DNS1 $New_DNS2" $> $logpath
 }


## This function deactivates the active profile and activates the new profile,
## then informs the user
Activate_New_Profile () {
   nmcli con down "$Active_Profile" && nmcli con up "$New_Profile" -a &> $logpath
   echo "Profile $New_Profile activated"
 }

## This script runs all the functions
Main () {
	echo $line
	Root_Check
	Log_And_Variables
	KDE_Check
	Filter_Active_Interfaces
	Active_Interfaces_Menu "${#Filtered_Active_Interfaces[@]}" "${Filtered_Active_Interfaces[@]}"
	Interface_Info
	User_Prompt
	Verify_Info
	Profile_Prompt
	Clone_Profile
	Activate_New_Profile
}

Main
