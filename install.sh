#!/bin/bash
#
#####################################
# pre-conditions
#####################################
#
# This was tested for
# - lubuntu 15.x
# - ubuntu-mate 16.x on raspberry pi 3
# This does not work for
# - debian 8 - ffmpeg is not available
# - debian 9 (stretch) - davfs2 is not available (at 02.04.2016)
#
#####################################
# user settings
#####################################
# optional- backup to USB
backup_device_name=/dev/sda1 # check with 'sudo fdisk -l' (type this command in a shell), 'lsblk'
backup_mount_point=/media/usbmotion
#backup_device_pass= # for encrypted usb sticks (LUKS + ext4)
#
# optional - backup to WebDAV (another computer in the internet)
url_webdav="https://domain.de/dav/myname" # server
user_webdav="myname@domain.de" # login name
pass_webdav=mypass # login pass
path_webdav=raspi-motion # optional.
#
# optional - start/stop automatically daily
daily_start=06 # hour. Examples '01' for 1 am, '16' for 4 pm
daily_stop=22 # hour
#
#
#####################################
# Do NOT edit below this line
#####################################
mkdir conf
user_motion=$USER
install_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Read Password
echo -n Password: 
read -s pass_root
echo
#
echo "user_motion=$user_motion" > util/user.txt
echo "install_dir=$install_dir" >> util/user.txt
echo "pass_root=$pass_root" >> util/user.txt
echo "backup_device_name=$backup_device_name" >> util/user.txt
echo "backup_device_pass=$backup_device_pass" >> util/user.txt
echo "backup_mount_point=$backup_mount_point" >> util/user.txt
echo "url_webdav=$url_webdav" >> util/user.txt
echo "user_webdav=$user_webdav" >> util/user.txt
echo "pass_webdav=$pass_webdav" >> util/user.txt
echo "path_webdav=$path_webdav" >> util/user.txt
echo "daily_start=$daily_start" >> util/user.txt
echo "daily_stop=$daily_stop" >> util/user.txt
chmod go-rw util/user.txt
#
if whereis sudo | grep "/usr/"
then
	echo "using sudo"
    if [ -f /etc/debian_version ]
    then
		if id $user_motion | grep sudo
		then
			echo "$pass_root" | sudo -S bash util/install_helper.sh
		else
        	echo "Is Debian but has sudo. Adding user $user_motion to group sudo ..."
			su -c "adduser $user_motion sudo"
			echo -n "$user_motion was added to group sudo. Please reboot and execute './install.sh' again. Reboot now? y/n:"
			read answer
			if [ $answer == "y" ]
			then
				su -c reboot
			else 
				exit
			fi
		fi
	else 
		echo "$pass_root" | sudo -S bash util/install_helper.sh
    fi
else
	echo "using su -c (Can't echo password to 'su -c'. You need to type the password again. Sorry for this.)"
	su -c "bash util/install_helper.sh"
fi
