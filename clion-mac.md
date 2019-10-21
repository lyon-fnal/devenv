# CLion for the Mac and the `devenv` containers

Adam Lyon (October 2019)
## Introduction

See the introduction in [CLion for Linux](clion-linux.md).

If you have not tried CLion before, you may want to start with [CLion for Linux](clion-linux.md) as configuring it is much easier than CLion for Mac. If you decide you like it, then come back here and do the instructions. If you do this, you should remove the CLion project files so that CLion for Mac won't get confused. You can do that with `rm -rf /path/to/devArea/srcs/.idea`. 

This document will guide you through using CLion on your Mac, but building, running and debugging a Fermilab physics experiment Linux application in a docker container. Unfortunately, CLion cannot deal directly with docker containers. It does have a *Remote Development* facility, but it works via `ssh` and wants to copy files locally. The `devenv` docker containers use your source code and build areas on your Mac filesystem, needing no copies. 

The advantages of running CLion for the Mac are clear when you start it. The fonts are exceptionally clear, the keyboard shortcuts are familiar, and some things even work better like debugging. 

## Preparing your Mac

There are a couple of things you need to do on your Mac to make this system work. 

First, set up the `devenv` containers as per the [README.md](README.md) file. 

### Install CVMFS
Then, you must install CVMFS on your Mac and configure it to mount the same CVMFS repositories that you use in the `devenv` container. You must do this so CLion can find headers and source code in `/cvmfs`. Unfortunately, despite haivng a `cvmfs_nfs_server` container that can serve CVMFS via NFS, there seems to be no way to export that to the host Mac. There are two main reasons for this deficiency,

* Docker for Mac does not expose the docker network to the Mac host. This is because docker actually runs a virtual machine behind the scenes and the Mac has no easy access to that.
* You can forward one or more ports to the Mac host, but NFSv3 uses many ports that will conflict with NFS running on your Mac (in order to serve your `/Users` area to the container). NFSv4 offers mounting nfs volumes with only one port, and that would be idea and even usable, but CVMFS does not seem to work with NFSv4. 

Because we are going to use CVMFS only for headers and some source code, the amount of data you'll cache from CVMFS on your Mac will be small.

### Perhaps install a late version  Linux CMake
If you want to do builds with `ninja` (yes, you do) instead of `make`, then you'll need a late version of CMake. To do builds with ninja, CLion requires CMake v3.15 or later - that's likely much later than what you use in your release and what is on SciSoft. Choose an area on your Mac (I do `/Users/lyon/Development/CMake`) and [download](https://cmake.org/download/) the **linux** (not Mac) CMake `.tar.gz` file (I did v3.15.4). `tar xf` the tar file to unwind it. 

## Installing CLion

 Install CLion for the Mac from [here](https://www.jetbrains.com/clion/download/#section=mac) or [here](https://www.jetbrains.com/clion/nextversion/) for EAP builds (early access program). I generally install the EAP because they have new features that I want, though they sometimes have problems. 
 
## Cloning this repository

We will be using some scripts in the `helpers` directory of this Github repository. You should `git clone` the repository to somewhere accessible from the container (e.g. under `/Users/<USER>/...`). 
 
## Preparing your development area and `docker-compose`

We want to be able to run commands in the container quickly with a minimum of startup time. We can do two things to make that happen...

* Incur the CVMFS mount time once and not per each command. We'll `docker-compose exec` into a container that already has CVMFS running. 
* We'll store the development environment (environment variables) and use `docker-compose` to quickly reinstate it when we run a command in the container with `docker-compose exec`.    
 
 Prepare the `docker-compose.yml` file as per [README.md](README.md) and start the `devenv-<NAME>` service (where `<NAME>` is the descriptive name you gave to identify the containers/service). For example `docker-compose up -d devenv-<NAME>`. Now, `docker-compose exec devenv-<NAME> /bin/bash` to start a shell. Set up your development area and checkout source code. 
 
 If you use the `art` framework, then you must make your own local release of `cetbuildtools`. That is because the `cetbuildtools` CMake macros perform a check that our scripts will violate. With your own version of `cetbuildtools`, you can circumvent the check. To do this, look at the version of cetbuildtools that you use (e.g. setup your environment to the point where you can do a build and look at `$CETBUILDTOOLS_DIR` and note the version). With your Mac web browser, go to https://scisoft.fnal.gov/scisoft/packages/cetbuildtools and find that version. Download the `cetbuildtools-XX-noarch.tar.bz2` to your `localProducts...` directory with `wget` and unwind with `tar xf <.tar.bz2> file`. Now do your build environment setup again (e.g. `. mrb s`).  Do `ups active` to ensure that `cetbuildtools` comes from your local products area. You can remove the tar file now. 
 
 You should also `setup gdb` and any other packages that aren't yet set up (rare).
 
 Now, `cd` to your docker directory for this development area (where your `docker-compose.yml` file is located). Run a script from the devenv repository helpers directory,
 
 ```bash
/path/to/devenv/helpers/make_env.sh > <ENV_NAME>.env
 ```

where `<ENV_NAME>` is some descriptive name that describes the environment like `build`. Or it can be the same as `<NAME>` you've used elsewhere.  

If you look at that file, you'll see it contains all (nearly all) of the environment variables you have set. We can restore this environment using `docker-compose` for very fast start up.

IMPORTANT: Now, exit from the shell and bring down the container with `docker-compose down`.

### Changes to `docker-compose.yml`

Now, on the Mac with an editor, edit the `docker-compose.yml` for your development area. First, uncomment the two lines under `x-env-file: &default-env-file` to read,

```yaml
x-env-file: &default-env-file
  env_file
    - ./<ENV_NAME>.env
```

Wheere `<ENV_NAME>` is the name you chose earlier.

Now, also uncomment the two lines each under `x-volumes1` and `x-volumes2` involving mounting `/private` and `/Applications` (so uncomment four lines total). The docker container will need access to those areas.

Now, uncomment the last line of the block with `x-worker`. That is,
```yaml
  <<: *default-environment   # I uncommented
``` 
 
 Start up the container again with 
 ```bash
docker-compose up -d devenv-<NAME>
 ```
and wait for CVMFS to start up (`docker-compose logs -f devenv-<NAME>`).

For fun, `docker-compose exec` into a shell (see above). You'll see that your development is magically set up already! No need to source any scripts! This happens because we are passing in the list of environment variables and they are being set before you get the shell prompt. You can verify with `ups active`. Note that shell functions are **not** passed into the environment. That means that the UPS `setup` function (yes, it's a bash function, not a script) will not work. If you really need to setup another package in your shell, you can do `source ups setup ...` where the `...` is the specifier for the package like you would do for regular `setup`. If you need that package for builds and such, then set it up, check `ups active` and redo the `make_env.sh` step above. Then exit the shell and restart the container. 

## Creating the helper scripts

Our strategy will be to create a toolchain for `cmake`, compilers and `gdb` that will call our helper scripts that, in turn, will run the corresponding program in the container. CLion cannot do this for docker containers out of the box (a different JetBrains product, `PyCharm`, can for Python - maybe CLion will add this functionality one day). Since CMake will be calling these helper scripts, we are not able to add extra logic or arguments (e.g. we cannot write one helper script to rule them all). 

