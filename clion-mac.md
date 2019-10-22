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
 
 NOTE: If you downloaded a late version of `cmake`, then you need to fix your environment to use it...
```shell script
# To use late version of CMake
unsetup cmake  # Do not use the UPS version
export PATH=/path/to/CMake/directory/bin:$PATH  # Be sure first item ends in bin, not cmake
```
 
 Now, `cd` to your docker directory for this development area (where your `docker-compose.yml` file is located). Run a script from the devenv repository helpers directory,
 
 ```shell script
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
 ```shell script
docker-compose up -d devenv-<NAME>
 ```
and wait for CVMFS to start up (`docker-compose logs -f devenv-<NAME>`).

For fun, `docker-compose exec` into a shell (see above). You'll see that your development is magically set up already! No need to source any scripts! This happens because we are passing in the list of environment variables and they are being set before you get the shell prompt. You can verify with `ups active`. Do `cmake --version` to make sure you have the correct `cmake`. Note that shell functions are **not** passed into the environment. That means that the UPS `setup` function (yes, it's a bash function, not a script) will not work. 
 If you need `setup` and/or `unsetup` restored, you can, within the container, `source /path/to/devenv/helpers/restore_ups_setup`. If you need an extra package for builds and such, then set it up, check `ups active` and redo the `make_env.sh` step above. Then exit the shell and restart the container. 

## Creating the helper scripts

Our strategy will be to create a toolchain for `cmake`, compilers and `gdb` that will call our helper scripts that, in turn, will run the corresponding program in the container. CLion cannot do this for docker containers out of the box (a different JetBrains product, `PyCharm`, can for Python - maybe CLion will add this functionality one day). Since CMake will be calling these helper scripts, we are not able to add extra logic or arguments (e.g. we cannot write one helper script to rule them all). 

To make the helper scripts, see and follow the instructions in `/path/to/devenv/helpers/runWithDockerExec-TEMPLATE`. 

You will end up with six files in the `helpers` directory; five of which are symbolic links. 
```shell script
cmake -> runWithDockerExec
g++ -> runWithDockerExec
gcc -> runWithDockerExec
make -> runWithDockerExec
<EXP> -> runWithDockerExec  # Where <EXP> is experiment's art program like gm2 or nova
runWithDockerExec
```

We will use the `cmake`, `g++`, and `gcc` soft links for running those commands in the container. You should try to run them and make sure they work and you get the correct versions. (the container must be running).
```shell script
./cmake --version  # An error about lack of CMAKE_ROOT may be ignored
./g++ --version
./gcc --version
./<EXP> --version
```

## Running CLion

Be sure your `devenv-<NAME>` container is up and running with CVMFS mounted. 

Start the CLion Mac application. If this is the first time you are running CLion, you will need to do some configuration. Just follow all the steps. When it asks you for a toolchain, leave the defaults as they are and continue. 

### Open the project

If you've used CLion before, it will open the previously used project. If that's not what you want, select the menu option `File -> Close Project`.

To open a project, click on `Open` (the other options will make a new empty `CMakeLists.txt` file and that's typically not what you want to do) and navigate to the directory on your Mac that contains the top level `CMakeLists.txt` file (typically `/path/to/your/dev/area/srcs`). 

The first time you open the project, `cmake` will start running and it will fail. We'll fix that in a moment. 

You may notice that the name of your project is `srcs` (e.g. from the title of the main CLion window). That is because CLion simply uses the directory name for the project name. You can change that to a more useful name, though strangely, there is no way to do this from within CLion itself. Instead, from a shell prompt, do

```bash
cd /path/to/dev_area/srcs
echo '<Project name>' > .idea/.name
```
where `Project name` is the name you want for the project. The next time you start CLion, it will use that name for the project.

Now, let's fix the CMake problem. You should see a `CMake` window with the failure. To the left of that window are some icons. Click on the Settings icon (the gear wheel) and select "CMake settings". Change the "Generation path" to the build directory for your development area (e.g. for me it may be `/path/to/dev_area/build_slf6.x86_64`). 

Now, select `Toolchains` on the left. This will bring up the toolchains pane. Click on the "+" to make a new Toolchain. Select `System` (**not** Remote) and give it a name like your development area or `<NAME>` that you've used elsewhere. Now, click on the three dot buttons and select the helper sym-links. Note that when you select a sym-link, CLion will unhelpfully resolve it and replace it with the target script. That's not what you want. Edit the path in the text bar and restore the sym-link name. Once you do one setting, you can copy, paste, and modify for the others. Do not press "enter" or "return" on this dialog box, as that will close the box. See the figure below. Note that I have a Homebrew version of gdb. 

![CMake Mac Toolchain](documentation/clion_mac_toolchain.png)

CLion will run some tests and give you the versions of CMake and gdb. Be sure these are correct (especially CMake). 

Now, to back to the CMake settings (`CMake` on the left toolbar under Toolchains). Be sure the Generation Path is correct (you set that before) and, assuming you want to run `ninja` (yes, you do), add the following to `CMake options`:
```
-DCMAKE_MAKE_PROGRAM=ninja -Wno-dev -G Ninja
```
The `-Wno-dev` turns off some (but not all) warnings that the later versions of CMake spit out. Your window should look like the following picture.

![CMake settings](documentation/cmake_settings.png)

Click on "OK". CMake should start to run, but it won't get far. You should see an error like the below,

![CMake error](documentation/cmake_compiler_error.png)

This is `cetbuildtools` checking the path of gcc and failing when it isn't what it expects. We need to remove this failure mode. Click on the highlighted file in the error to bring it up in the editor. See the figure.  

![CMake fix](documentation/clion-error-fix.png)

Highlight the `if` block as indicated and simply delete it. 

Now run CMake again (click on the circular arrows in the CMake window). An error for g++ will occur. Fix it the same way as before and run CMake again.

And now CMake should run to completion! You may see some warnings and you may ignore then. 

After CMake finishes, CLion will gather symbol information and index the code (you'll see an indication of this in the status bar at the bottom of the CLion window). This may take a long time and some functionality is limited while this is happening. It only takes a long time the first time it indexes. 



  


## Appendix



`
