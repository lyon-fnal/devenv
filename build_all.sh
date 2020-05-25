#!/bin/bash

# Build all of the images in the correct order

cd devenv_sl6
docker build -t lyonfnal/devenv:sl6 .

cd ../devenv_sl7
docker build -t lyonfnal/devenv:sl7 .

cd ../devenv-cvmfs
docker build -t lyonfnal/devenv_cvmfs:sl6 -f Dockerfile-sl6 .
docker build -t lyonfnal/devenv_cvmfs:sl7 -f Dockerfile-sl7 .
 
cd ../devenv-cvmfs-vnc
docker build -t lyonfnal/devenv_cvmfs_vnc:sl6 -f Dockerfile-sl6 .
 
cd ../devenv-cvmfs-nfsserver
docker build -t lyonfnal/devenv_cvmfs_nfsserver:sl6 -f Dockerfile-sl6 .
 
cd ../devenv-cvmfs-nfsclient
docker build -t lyonfnal/devenv_cvmfs_nfsclient:sl6 -f Dockerfile-sl6 .
