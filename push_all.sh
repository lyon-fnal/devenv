#!/bin/bash

# Push all images

# Note that we must push all of them (not just the bottom of the dependency tree) in order to get the tags right.
docker push lyonfnal/devenv:sl6
docker push lyonfnal/devenv_cvmfs:sl6
docker push lyonfnal/devenv_cvmfs_vnc:sl6
docker push lyonfnal/devenv_cvmfs_nfsserver:sl6
docker push lyonfnal/devenv_cvmfs_nfsclient:sl6
