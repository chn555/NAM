
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
	user_path=/home/$orig_user
	logpath=$user_path/Automated-Installer-Log/error.log
	####  Varibale	####

	## Check if log folder exits, if not, create it
	if ! [[ -d $user_path/Automated-Installer-Log ]]; then
		sudo runuser -l $orig_user -c "mkdir $user_path/Automated-Installer-Log"
	fi

	## Check if error log exits, if not, create it
	if ! [[ -e $errorpath ]]; then
		sudo runuser -l $orig_user -c "touch $errorpath"
	fi

	## Check if output log exits, if not, create it
	if ! [[ -e $outputpath ]]; then
		sudo runuser -l $orig_user -c "touch $outputpath"
	fi
}

## Check if kde is installed, if it is, notify the user that wireless profiles
## might not work
KDE_Check () {
  if [[ $( echo $DESKTOP_SESSION | grep plasma ) ]] ; then
    echo "NAM has detected you are using KDE,
    due to the way KDE stores wireless passwords
    the wireless profiles NAM creates might not work."
  fi
}

## Filter active network interfaces, ignoring any interfaces that are not
## ethernet or wireless
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

## If more than one exists prompt the user, if only one exists chose that one
## and notify the user, if no interfaces exist exit the program
Menu_Active_Interfaces (){
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
