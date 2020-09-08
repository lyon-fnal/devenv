#!/bin/bash

# Based on https://success.docker.com/article/use-a-script-to-initialize-stateful-container-data
# Enviornment variable CVMFS_EXP must be set

set -e   # Exit immediately if something returns non-zero status

if [[ -z "${CVMFS_EXP}" ]]; then
 echo "Environment variable CVMFS_EXP must be set"
 exit 1
fi

# Making directories
mkdir -p /cvmfs/config-osg.opensciencegrid.org
mkdir -p /cvmfs/fermilab.opensciencegrid.org

IFS=':'
for x in $CVMFS_EXP
do
    mkdir -p /cvmfs/"$x"
done

# We need to mount CVMFS
echo "Mounting CVMFS for $CVMFS_EXP"

 # Check for the fuse group (SL7 doesn't seem to add it)
getent group fuse || groupadd fuse && usermod -a -G fuse cvmfs 

chgrp fuse /dev/fuse || (echo 'Did you docker run with --privileged?' && exit 1)

mount -t cvmfs config-osg.opensciencegrid.org /cvmfs/config-osg.opensciencegrid.org
mount -t cvmfs fermilab.opensciencegrid.org   /cvmfs/fermilab.opensciencegrid.org

IFS=':'
for x in $CVMFS_EXP
do
    mount -t cvmfs "$x"     /cvmfs/"$x"
done


echo "Checking mounts"
/usr/bin/cvmfs_config probe
