#!/bin/bash

# Build all of the images in the correct order

cd devenv_sl6
docker build -t lyonfnal/devenv:sl6 .

cd ../devenv-cvmfs_sl6
docker build -t lyonfnal/devenv_cvmfs:sl6 .
 
cd ../devenv-cvmfs-vnc_sl6
docker build -t lyonfnal/devenv_cvmfs_vnc:sl6 .
 
cd ../devenv-cvmfs-nfsserver_sl6
docker build -t lyonfnal/devenv_cvmfs_nfsserver:sl6 .
 
cd ../devenv-cvmfs-nfsclient_sl6
docker build -t lyonfnal/devenv_cvmfs_nfsclient:sl6 .
