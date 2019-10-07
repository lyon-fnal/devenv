# Start CVMFS
/usr/local/bin/start_cvmfs.sh

# Run forever to act like a server
echo "Running until killed"
exec tail -f /dev/null
