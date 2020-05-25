#!/bin/bash

set -e

mkdir -p /cvmfs/config-osg.opensciencegrid.org
mount -t nfs -o ro,nolock,noatime,ac,actimeo=60 cvmfs_nfs_server:/cvmfs/config-osg.opensciencegrid.org /cvmfs/config-osg.opensciencegrid.org

mkdir -p /cvmfs/fermilab.opensciencegrid.org
mount -t nfs -o ro,nolock,noatime,ac,actimeo=60 cvmfs_nfs_server:/cvmfs/fermilab.opensciencegrid.org /cvmfs/fermilab.opensciencegrid.org

mkdir -p /cvmfs/${CVMFS_EXP}.opensciencegrid.org
mount -t nfs -o ro,nolock,noatime,ac,actimeo=60 cvmfs_nfs_server:/cvmfs/gm2.opensciencegrid.org /cvmfs/${CVMFS_EXP}.opensciencegrid.org

exec "$@"
