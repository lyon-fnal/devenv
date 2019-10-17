#!/bin/bash

/usr/local/bin/start_cvmfs.sh
/usr/local/bin/start_nfs_server.sh

# Run forever to act like a server
echo "Running until killed"
exec tail -f /dev/null
