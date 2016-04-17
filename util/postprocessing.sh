#!/bin/bash
#

function writeUSB {
	echo "starting backup to USB ..."
	device_mounted=0
	if [ -n "$backup_device_name" ]
	then
		if [ -n "$backup_device_pass" ]
		then
			echo "found password for encrypted usb device $backup_device_name. Gheck if available (plugged in) ..."
			if sudo -S blkid | grep $backup_device_name
			then
				# encrypted usb
				echo "decrypting backup device..."
				echo "$backup_device_pass" | cryptsetup luksOpen $backup_device_name cryptobackup
				echo "mounting backup device..."
				if sudo mount /dev/mapper/cryptobackup $backup_mount_point
				then
				    device_mounted=1
				    echo "device $backup_device_name is now mounted. Starting backup..."
					cp -u $RESULTS/output*.avi $backup_mount_point
					cp -u $RESULTS/mylist*.txt $backup_mount_point
					mkdir -p $backup_mount_point/$LOG
					cp -ur $LOG $backup_mount_point
					echo "disk sizes..."
					df -h
				    echo "unmounting backup device..."
				    echo "$pass_root" | umount $backup_mount_point
				else
				    echo "failed to mount usb device $backup_device_name"
				fi
				echo "closing decrypted backup device..."
				sudo echocryptsetup luksClose cryptobackup
			else
				echo "FAILED: backup to encrypted usb failed. Reaason: found password for encrypte usb but it seems that the usb is not plugged in."
			fi
		else
			# not encypted usb
			echo "no encrypted usb device $backup_device_name"
			echo "check if USB ($backup_device_name) is available/plugged in ..."
			if sudo fdisk -l | grep -i "$backup_device_name"
			then
				echo "check if USB ($backup_mount_point) is mounted ..."
				if grep -qs "$backup_mount_point" /proc/mounts
				then
					echo "yes, $backup_mount_point is mounted already"
				else
					echo "no , $backup_mount_point is not mounted already. Mounting ..."
					if sudo mount $backup_device_name $backup_mount_point
					then
						device_mounted=1
						echo "device $backup_device_name is now mounted. Starting backup..."
						cp -u $RESULTS/output*.avi $backup_mount_point
						cp -u $RESULTS/mylist*.txt $backup_mount_point
						echo "disk sizes..."
						df -h
						echo "unmounting backup device..."
						sudo umount $backup_mount_point
					else
						echo "failed to mount usb device $backup_device_name"
					fi
				fi
			else
				echo "usb device $backup_device_name is not available (Ćheck wether it is plugged in.)"
			fi
		fi
	fi
	if [ $device_mounted == 0 ]
	then
		echo "device could not be mounted $backup_device_name."
	fi
	echo "leaving backup to USB"
}

function writeCloud {
	echo "starting backup to cloud..."
	# http://skripta.de/Davfs2.html
	# http://johnreid.it/2009/09/26/mount-a-webdav-folder-in-ubuntu-linux/
	davdirroot=/home/$user_motion/webdav
	davdir=/home/$user_motion/webdav
	echo "check if webdav dir ($davdir) is mounted ..."
	if grep -qs "$davdir" /proc/mounts
	then
		echo "yes, $davdir is mounted already"
	else
		echo "no , $davdir is not mounted already. Mounting ..."
		mount $davdir
		if [ $? -eq 0 ]
		then
			echo "success: $davdir is mounted now"
		else
			echo "FAILED: Something went wrong with mounting $davdir"
			echo "WARNING: Did not upload files to $url_webdav"
			return
		fi
	fi
	if [ -n "$path_webdav" ]
    then
		davdir="/home/$user_motion/webdav/$path_webdav"
		if [ ! -d "$davdir" ]
		then
			echo "Try 'mkdir $davdir' ..."
			mkdir $davdir
		fi
    fi
	echo "copying videos and file list to cloud ($url_webdav/$path_webdav) ..."
	# cp -ur $RESULTS/*$NOW.* $davdir
	cp -ur $RESULTS/*.* $davdir
	if [ ! -d "$davdir/$LOG" ]
    then
		echo "Try 'mkdir $davdir/$LOG' ..."
		mkdir $davdir/$LOG
    fi
	echo "copying log files to cloud ($url_webdav) ..."
	cp -ur $LOG $davdir
	echo "unmounting webdav..."
	umount $davdirroot
	echo "finished backup to cloud"
}

function cleanup {
	echo "removing all JPGs in folder 'motion'"
	rm motion/*.jpg
	for f in motion/*.avi
		do
		if [[ $f != *"$NOW"* ]]
		then
			echo "removing $f"
			rm -f $f
		fi
	done
}

function writeVideo {
	rm mylist_$NOW.txt
	NOW_Time=$(date +"%m-%d-%Y_%H-%M-%S")
	echo "find all videos from today and sort them by time ..."
	files=($(ls -tr motion/*$NOW*.avi))
	for item in ${files[*]}
	do
		echo "video to concat '$item'"
		echo "file '$item'" >> mylist_$NOW_Time.txt
	done
	echo "concatenate videos from today..."
	ffmpeg -y -f concat -i mylist_$NOW_Time.txt -c copy output_$NOW_Time.avi
	echo "moving videos and files lists to results folder..."
	mv -f output*.avi $RESULTS/
	mv -f mylist*.txt $RESULTS/
}

source util/user.txt
RESULTS=results
LOG=log
# NOW=$(date +"%m-%d-%Y_%H-%M-%S")
NOW=$(date +"%Y%m%d")
# call 'sudo -S' once
echo "$pass_root" | sudo -S ifconfig
writeVideo
writeUSB
writeCloud
cleanup


