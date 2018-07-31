
#!/usr/bin/env bash


################################################################################
# Author :	BigRush && chn555
#
# License :  GPLv3
#
# Description :  NAM (Network Automated Manager).
#				 This script will use nmcli to set up static ip efortlessly.
#
# Version :  2.0.1
################################################################################
NAM_Version="2.0.1"

OPTS=$(getopt -o hfVi:p: --long ipv4:,gateway:,netmask:,dns1:,dns2:,runasroot,help -n 'parse-options' -- "$@")
if [ $? != 0 ] ; then
	echo "Invalid arguments" >&2
	echo "Use -h for help"
	exit 1 ;
fi
eval set -- "$OPTS"

Help_ARG=0
Force_ARG=0
Version_ARG=0
Interface_ARG=0
Profile_ARG=0
Ipv4_ARG=0
Gateway_ARG=0
Netmask_ARG=0
DNS1_ARG=0
DNS2_ARG=0
Runasroot_ARG=0


while true; do
	case "$1" in
		-h|--help) Help_ARG=1; shift ;;
		-f )	Force_ARG=1; shift ;;
		-V ) Version_ARG=1; shift ;;
		-i ) Interface_ARG=$2; shift 2;;
		-p ) Profile_ARG=$2; shift 2 ;;
		--ipv4 ) Ipv4_ARG=$2; shift 2 ;;
		--gateway ) Gateway_ARG=$2; shift 2 ;;
		--netmask ) Netmask_ARG=$2; shift 2 ;;
		--dns1 ) DNS1_ARG=$2; shift 2 ;;
		--dns2 ) DNS2_ARG=$2; shift 2 ;;
		--runasroot ) Runasroot_ARG=1; shift ;;
		-- ) shift; break ;;
		-* | --*) Help_ARG=1; shift;;
		* ) break ;;
	esac
done


## Checks if the script runs as root
Root_Check () {
	if [[ $Runasroot_ARG -eq 1 ]]; then
		return 0
	elif  [[ $EUID -eq 0 ]]; then
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
		elif [[ Scripted -eq 1 ]]; then
		 		echo  "More then one interface was found,
				this is not supported in non-interactive mode,
				please use -i to select an interface"
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
		Verify_Info
  fi
}


## This function asks the user for the new profile name,
## if the name is used already it will run the Overwrite_Profile_Loop,
## otherwise it will continue will the entered name.
Profile_Prompt () {
	echo $line
	read -p "Enter the name of the new profile : " Temp_Profile
	while [[ $Temp_Profile == "" ]]; do
  	read -p "Enter the name of the new profile : " Temp_Profile
	done
  nmcli con show "$Temp_Profile"  &> $logpath
  if [[ $? == 0 ]];then
    Overwrite_Profile_Prompt "$Temp_Profile"
  else
    New_Profile=$Temp_Profile
		Clone_Profile
  fi
}


## This function will only be used if the user has entered a profile name that is in use.
## The function will notify him the name is in use and ask him to overwrite the existing profile.
Overwrite_Profile_Prompt () {
  read -p "$1 already exists, override? [N,y]" Override
  if  [[ $Override == "y" ]] || [[ $Override == "Y" ]]; then
		New_Profile=$Temp_Profile
    nmcli con mod "$New_Profile" ipv4.method manual ipv4.addr "$New_Ip/$New_Netmask" ipv4.gateway "$New_Gateway" ipv4.dns "$New_DNS1 $New_DNS2" &> $logpath
		Active_Profile=$( nmcli --t -f NAME,UUID,TYPE,DEVICE con show --active |  grep $option |cut -d ":" -f 1 )
  elif [[ $Override == "" ]] || [[ $Override == "n" ]] || [[ $Override == "N" ]]; then
    echo " "
    echo $line
    Profile_Prompt
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
  nmcli con mod "$New_Profile" ipv4.method manual ipv4.addr "$New_Ip/$New_Netmask" ipv4.gateway "$New_Gateway" ipv4.dns "$New_DNS1 $New_DNS2" &> $logpath
 }


## This function deactivates the active profile and activates the new profile,
## then informs the user
Activate_New_Profile () {
   nmcli con down "$Active_Profile" && nmcli con up "$New_Profile" -a
   echo "Profile $New_Profile activated"
 }


## Checks if the ip address conforms to ipv4 format
Ipv4_Verify () {
	oct='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
  ip4="^$oct\\.$oct\\.$oct\\.$oct$"
	if [[ "$1" =~ $ip4 ]]; then
		return 0
	else
		return 1
	fi
}

## Display help to the user
Help_Function () {
printf "%s" "\
Usage: nama --option \"value\" --option \"value\"
nama (Network Automated Manager)
This script will use nmcli to set up static ip efortlessly.

Options:

    -f                          if profile name is used, force overwrite

    -i <Active interface>       active interface to be used

    -p <Profile name>           name of the profile to be created

    --ipv4 <ipv4 address>       valid ipv4 address to be used

    --netmask <netmask>         netmask to be used, in bit-length format

    --gateway <gateway>         gateway address to be used

    --dns1 <dns address>        primary name server address to be used

    --dns2 <dns address>        secondary name server address to be used

    --runasroot                 Enable the option to run the script as root


Example:

	sudo nama -i enp0s3 -p test --ipv4 192.168.1.1 --netmask 24 --gateway 192.168.1.10 --dns1 1.1.1.1 --dns2 9.9.9.9 --runasroot

Authors:

	chn555
		https://github.com/chn555

	BigRush
		https://github.com/BigRush



For any bugs please report to https://github.com/chn555/nama/issues

"
}

## This script runs all the functions
Main () {
	if [[ $Version_ARG -eq 1 ]]; then
		echo "NAM version $NAM_Version"
	fi
	## Verify that no argument is being used, and use the standard version
	if [[ "$Ipv4_ARG" == 0 ]] && [[ $Gateway_ARG == 0 ]] && \
	[[ $Netmask_ARG == 0 ]] && [[ $DNS1_ARG == 0 ]] && \
	[[ $DNS2_ARG == 0 ]] && [[ $Profile_ARG == 0 ]] && \
	[[ $Force_ARG -eq 0 ]] && [[ $Help_ARG -eq 0 ]] ; then
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
		Activate_New_Profile
		exit 0
	## Check if all the flags needed to be configured are used, and no interfearing
	## flags have been used
elif [[ $Ipv4_ARG != 0 ]] && [[ $Gateway_ARG != 0 ]] && \
	[[ $Netmask_ARG != 0 ]] && [[ $DNS1_ARG != 0 ]] && \
	[[ $DNS2_ARG != 0 ]] && [[ $Profile_ARG != 0 ]] && \
	[[ $Help_ARG -eq 0 ]] ; then
		Scripted=1
		if ! Ipv4_Verify $Ipv4_ARG ;then
			echo "IP address is invalid, exiting" |tee $logpath
			exit 1
		elif ! Ipv4_Verify $Gateway_ARG ;then
			echo "gateway is invalid, exiting" |tee $logpath
			exit 1
		elif ! Ipv4_Verify $DNS1_ARG ;then
			echo "DNS1 is invalid, exiting" |tee $logpath
			exit 1
		elif ! Ipv4_Verify $DNS2_ARG ;then
			echo "DNS2 is invalid, exiting" |tee $logpath
			exit 1
		elif [[ ! "$Netmask_ARG" -gt 1  ||  ! "$Netmask_ARG" -lt 32 ]] ;then
			echo "Netmask is invalid, exiting" |tee $logpath
			exit
		fi
		Root_Check
		Log_And_Variables
		KDE_Check
		if [[ $Interface_ARG == 0 ]]; then
			Filter_Active_Interfaces
			Active_Interfaces_Menu "${#Filtered_Active_Interfaces[@]}" "${Filtered_Active_Interfaces[@]}"
		elif ! [[ -z $(nmcli --t -f NAME,UUID,TYPE,DEVICE con show --active |  grep $Interface_ARG |cut -d ":" -f 1) ]] ; then
			option=$Interface_ARG
		else
			echo "$Interface_ARG in not an active interface, exiting"
			exit 1
		fi
		New_Ip=$Ipv4_ARG
		New_Netmask=$Netmask_ARG
		New_Gateway=$Gateway_ARG
		New_DNS1=$DNS1_ARG
		New_DNS2=$DNS2_ARG
		nmcli con show "$Profile_ARG"  &> $logpath
	  if [[ $? -eq 0 ]] && [[ $Force_ARG -eq 0 ]];then
			echo "Profile name is already in use,"
			echo "you can use -f to force overwrite"
	    exit 1
		elif nmcli con show "$Profile_ARG"  &> $logpath && [[ $Force_ARG -ne 0 ]]; then
			New_Profile=$Profile_ARG
			Active_Profile=$( nmcli --t -f NAME,UUID,TYPE,DEVICE con show --active |  grep $option |cut -d ":" -f 1 )
			nmcli con mod "$New_Profile" ipv4.method manual ipv4.addr "$New_Ip/$New_Netmask" ipv4.gateway "$New_Gateway" ipv4.dns "$New_DNS1 $New_DNS2" &> $logpath
	  else
	    New_Profile=$Profile_ARG
			Clone_Profile
	  fi
		Activate_New_Profile
		exit 0
	## check if only the Help flag is on
elif [[ $Ipv4_ARG == 0 ]] && [[ $Gateway_ARG == 0 ]] && \
	[[ $Netmask_ARG == 0 ]] && [[ $DNS1_ARG == 0 ]] && \
	[[ $DNS2_ARG == 0 ]] && [[ $Profile_ARG == 0 ]] && \
	[[ $Force_ARG -eq 0 ]] && [[ $Help_ARG -ne 0 ]] ; then
		Help_Function
		exit 0
	else
		echo "Missing arguments, use -h for help"
		exit 1
	fi
}

Main
