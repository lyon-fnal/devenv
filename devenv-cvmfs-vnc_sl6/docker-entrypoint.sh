#!/bin/bash

/usr/local/bin/start_cvmfs.sh

echo "Running VNC"
echo 'root:devenv' | chpasswd
printf "devenv\ndevenv\n\n" | vncpasswd
dbus-launch --sh-syntax  # See https://github.com/TigerVNC/tigervnc/issues/592#issuecomment-375856055
exec vncserver -geometry 2880x1800 -autokill -fg