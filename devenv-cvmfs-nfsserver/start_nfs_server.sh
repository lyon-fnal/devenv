#!/bin/bash

# Based on https://success.docker.com/article/use-a-script-to-initialize-stateful-container-data
# Enviornment variable CVMFS_EXP must be set

set -e   # Exit immediately if something returns non-zero status

if [[ -z "${CVMFS_EXP}" ]]; then
 echo "Environment variable CVMFS_EXP" must be set
 exit 1
fi

echo "Adding to NFS"
echo "/cvmfs/config-osg.opensciencegrid.org *(insecure,ro,sync,no_subtree_check,no_root_squash,fsid=101)" >> /etc/exports
echo "/cvmfs/fermilab.opensciencegrid.org *(insecure,ro,sync,no_subtree_check,no_root_squash,fsid=102)" >> /etc/exports
echo "/cvmfs/"${CVMFS_EXP}".opensciencegrid.org *(insecure,ro,sync,no_subtree_check,no_root_squash,fsid=103)" >> /etc/exports
chkconfig nfs on
rpcbind start
service nfs start
exportfs -arv
service nfs restart

echo "Serving NFS"