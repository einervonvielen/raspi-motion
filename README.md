# Turn you Raspberry Pi into a Spy Cam

Makes videos every time something moves in front of a webcam.

This is an automated install script for the programm [Motions](https://en.wikipedia.org/wiki/Motion_%28surveillance_software%29) on a linux machine.

This programm will store the videos
- on the local disk
- on the USB if plugged in
- on server (upload via webDAV) if provided by you at install time

## How to install?

Buy
- a [Rasberry Pi 3](https://en.wikipedia.org/wiki/Raspberry_Pi) (it could be another computer)
- a webcam
- optionally: a USB stick
- optionally: server providing webdav (example the community server [Hubzilla](https://github.com/redmatrix/hubzilla) that comes with a [script](https://github.com/redmatrix/hubzilla/tree/master/.homeinstall) for an unattended installation).

Install Linux an the Raspberry
- recommended [Ubuntu-Mate](https://ubuntu-mate.org/raspberry-pi/)

Download the automated installation

    git clone https://github.com/einervonvielen/raspi-motion

Edit the install.sh

    nano install.sh
    
Run install.sh

    ./install.sh
    
Configure motion if you do not want to use the defaults

    nano conf/motion.conf
    
## How to use?

### Start Motion

Motion is started automatically
- at start-up of computer
- every day at 06:00

Start manually with

    ./start.sh

### Stop Motion

The programm is stopped every day at 22:00.

Stop manually with

    ./stop
    
The stop.sh will store the videos
- on the local disk
- on the USB if plugged in
- on server (upload via webDAV) if provided by you at install time




