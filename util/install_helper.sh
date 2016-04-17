#!/bin/bash
#
# Doku http://www.lavrsen.dk/foswiki/bin/view/Motion/WebHome
#
# Supportive
# Doku http://www.netzmafia.de/skripten/hardware/Webcam/
# 
#     sudo apt-get install fswebcam gpicview fbi
#     fswebcam -v -r "640×480" test.jpg
#     gpicview test.jpg
#
#     v4l-utils
#       v4l2-ctl --list-ctrls
#       v4l2-ctl --set-ctrl brightness=200
#     guvcview v4l2ucp
#
function update_upgrade {
    echo "update and upgrade..."
    # Run through the apt-get update/upgrade first. This should be done before
    # we try to install any package
    apt-get -q -y update && apt-get -q -y dist-upgrade
    echo "updated and upgraded linux"
}

function nocheck_install {
    # export DEBIAN_FRONTEND=noninteractive ... answers from the package configuration database
    # - q ... without progress information
    # - y ... answer interactive questions with "yes"
    # DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends -q -y install $2
    # DEBIAN_FRONTEND=noninteractive apt-get --install-suggests -q -y install $1
    DEBIAN_FRONTEND=noninteractive apt-get -q -y install $1
    echo "installed $1"
}

function set_permissions {
    echo "adding user $user_motion to group motion"
	#useradd -G motion $user_motion
	adduser $user_motion motion
	adduser $user_motion sudo
}

function configuration {
	echo "making some configurations - copy motion.conf"
	# conf
	cp -f /etc/motion/motion.conf $install_dir/conf/motion.conf
	echo "changing motion.conf"
	chown $user_motion $install_dir/conf/motion.conf
	# dir the camera writes to
	mkdir -p $install_dir/motion
	chown $user_motion $install_dir/motion
	sed -i "s#^target_dir /var/lib/motion#target_dir $install_dir/motion#" $install_dir/conf/motion.conf
	#sed -i "s/^text_double off.*$/text_double on/" $install_dir/conf/motion.conf
	#sed -i "s/^width.*$/width 352/" $install_dir/conf/motion.conf
	#sed -i "s/^height.*$/height 288/" $install_dir/conf/motion.conf
	# log
	mkdir -p $install_dir/log
	chown $user_motion $install_dir/log
	chmod ugo+w $install_dir/log
	sed -i "s#^logfile /var/log/motion/motion.log#process_id_file $install_dir/log/motion.log#" $install_dir/conf/motion.conf
}

function configureUSB {
	echo "configure backup to USB ..."
	if [ -z "$backup_device_name" ]
    then
		echo "backup to USB not enabled - missing 'backup_device_name' in 'start.sh'"
        return
    fi
	if [ -z "$backup_mount_point" ]
    then
		echo "backup to USB not enabled - missing 'backup_mount_point' in 'start.sh'"
        return
    fi
	nocheck_install cryptsetup
	mkdir -p $backup_mount_point
	chown $user_motion $backup_mount_point
}

function configureWebDAV {
	# http://skripta.de/Davfs2.html
	# http://ajclarkson.co.uk/blog/auto-mount-webdav-raspberry-pi/
	echo "check if the user wants to use WebDAV"
	if [ -z "$url_webdav" ]
    then
		echo "backup to internet (WebDAV) not enabled - missing 'url_webdav' in 'start.sh'"
        return
    fi
	if [ -z "$user_webdav" ]
    then
		echo "backup to internet (WebDAV) not enabled - missing 'user_webdav' in 'start.sh'"
        return
    fi
	if [ -z "$pass_webdav" ]
    then
		echo "backup to internet (WebDAV) not enabled - missing 'pass_webdav' in 'start.sh'"
        return
    fi
	echo "yes, the user wants to use WebDAV (user defined: url, login, pass)"
	echo "configure backup to WebDAV ..."
	nocheck_install davfs2
	echo "making WebDAV available for users other then root"
	chmod u+s /usr/sbin/mount.davfs # or sudo dpkg-reconfigure davfs2
	echo "add $user_motion to group davfs2"
	usermod -a -G davfs2 $user_motion
	echo "make some configurations for WebDAV"
	mkdir -p /home/$user_motion/webdav
	if [ -z "`grep 'davfs' /etc/fstab`" ]
    then
        echo "$url_webdav/ /home/$user_motion/webdav davfs rw,noauto,user 0 0" >> /etc/fstab
    fi
	echo "reload fstab with 'mount -a' ..."
	mount -a
	mkdir -p /home/$user_motion/.davfs2
	echo /home/$user_motion/webdav $user_webdav $pass_webdav > /home/$user_motion/.davfs2/secrets
	chown -R $user_motion /home/$user_motion/.davfs2
	chmod 600 /home/$user_motion/.davfs2/secrets
	cp /etc/davfs2/davfs2.conf /home/$user_motion/.davfs2/
	# optional in /home/$user_motion/.davfs2/.davfs2/davfs2.conf
	#   if_match_bug 1
	#   use_locks 0
	#   cache_size 1 
	#   table_size 4096
	#   delay_upload 1
	#   gui_optimize 1
}

function configureCron {
	# check values
	if [ -z "$daily_start" ]
    then
		echo "daily automatic start not enabled - missing 'daily_start' in 'start.sh'"
        return
    fi
	if [ -z "$daily_stop" ]
    then
		echo "daily automatic start not enabled - missing 'daily_stop' in 'start.sh'"
        return
    fi
	# set cron
	echo "enabling daily automatic start/stop ($daily_start/$daily_stop) ..."
    if [ -z "`grep 'start.sh' /etc/crontab`" ]
    then
        echo "@reboot $user_motion cd $install_dir; ./start.sh >> /dev/null 2>&1" >> /etc/crontab
        echo "00 $daily_start * * * $user_motion cd $install_dir; ./start.sh >> /dev/null 2>&1" >> /etc/crontab
    fi
    if [ -z "`grep 'stop.sh' /etc/crontab`" ]
    then
        echo "00 $daily_stop * * * $user_motion cd $install_dir; ./stop.sh >> /dev/null 2>&1" >> /etc/crontab
    fi
}

source util/user.txt
echo "user = $user_motion , webDAV url = $url_webdav , webDAV user = $user_webdav , webDAV pass = $pass_webdav , root pass =  $pass_root , install dir = $install_dir"
update_upgrade
nocheck_install motion
nocheck_install ffmpeg
nocheck_install fswebcam
nocheck_install gpicview
nocheck_install fbi
set_permissions
configuration
configureUSB
configureWebDAV
configureCron
nocheck_install "sudo" # needed for postprocessing script
mkdir -p results
chown $user_motion results
echo "rebooting .,."
reboot

