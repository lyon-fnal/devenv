#!/bin/bash

# Build all of the images in the correct order

cd devenv_sl6
docker build -t lyonfnal/devenv:sl6 .

cd ../devenv_sl7
docker build -t lyonfnal/devenv:sl7 .

cd ../devenv-cvmfs
docker build -t lyonfnal/devenv_cvmfs:sl6 -f Dockerfile-sl6 .
docker build -t lyonfnal/devenv_cvmfs:sl7 -f Dockerfile-sl7 .
 