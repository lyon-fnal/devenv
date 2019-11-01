# devenv - A development environment for the Mac
Adam L. Lyon, October 2019

* [devenv \- A development environment for the Mac](#devenv---a-development-environment-for-the-mac)
  * [Introduction](#introduction)
  * [Why Docker containers?](#why-docker-containers)
  * [Assumptions](#assumptions)
  * [Details](#details)
  * [Installation](#installation)
    * [Install and prepare Docker for Mac](#install-and-prepare-docker-for-mac)
    * [Prepare NFS on your Mac](#prepare-nfs-on-your-mac)
  * [The docker images](#the-docker-images)
  * [Which image to use?](#which-image-to-use)
    * [I still don't know which image to use](#i-still-dont-know-which-image-to-use)
  * [Running the containers with docker\-compose](#running-the-containers-with-docker-compose)
    * [Setting up docker\-compose](#setting-up-docker-compose)
    * [Notes about docker\-compose](#notes-about-docker-compose)
    * [Features of  docker\-compose\.yml file](#features-of--docker-composeyml-file)
  * [Running](#running)
    * [Run a long lived container](#run-a-long-lived-container)
    * [Running ephemeral containers](#running-ephemeral-containers)
    * [Some notes](#some-notes)
    * [Connecting to the container with VNC](#connecting-to-the-container-with-vnc)
  * [Doing stuff](#doing-stuff)
    * [Examining container resource usage with netdata](#examining-container-resource-usage-with-netdata)
    * [Running CLion](#running-clion)
    
## Introduction
Linux style development, like what we do for particle physics experiments at Fermilab, is becoming more difficult on the Mac. Apple is moving to its own style of development that is often incompatible. For example,
* System Integrity Protection (SIP) prevents using `DYLD_LIBRARY_PATH`, breaking the mechanism used by our development environment system, `ups`.
* Mac headers and system libraries are not always compatible with those on Linux, necessitating platform dependent code. 
* XCode is more focused on Swift, Objective-C, and Mac or iOS-style development. XCode does not understand CMake builds natively. 

The differences that Mac and XCode introduce are difficult to manage and many experiments have stopped making Mac builds. Despite these problems, Mac laptops remain powerful machines and the MacOS environment is advantageous in many other areas. Therefore, mitigating the problems with Linux style development is motivated.

This package contains a configuration for `docker` containers along with instructions for integrating with the Mac that make for an effective and efficient development platform for Linux style development of physics code. Instructions for using [CLion](https://www.jetbrains.com/clion/) for C++ development in this environment are given in the documentation for running CLion within the [linux container](clion-linux.md) or from the [Mac host](clion-mac.md).  

Note that the containers and techniques here may also work on Windows. You will have to adapt these instructions for that platform. 

## Why Docker containers?

There are three ways to do Linux style development on the Mac

1. Not do it (resistance is futile) - that is conform to the Mac development style. As discussed above, this solution is becoming too difficult and costly to maintain. The vast majority of scientific code development is targeted at Linux. The more the Mac diverges, the more difficult it is to maintain a pure Mac development environment. 
1. Run a Linux virtual machine with [Virtual Box](https://www.virtualbox.org) and [vagrant](https://www.vagrantup.com). A Virtual Box Linux VM is a heavyweight virtualization solution that is complicated to set up and maintain. `vagrant` makes configuration and management easier though not simple. Virtual Box VMs are also difficult to distribute. One advantage here is that many Mac IDEs that support remote development do so with `ssh`, which is the preferred way to interact with a VM. 
1. Run a Linux Docker Container. [Docker](https://www.docker.com) containers are lightweight virtualization solutions, relatively easy to set up and configure and are portable to other systems that run Docker or [Singularity](https://sylabs.io). A disadvantage is that running `ssh` in the container is not the "docker way", therefore integration with remote development capable IDEs is more difficult, but not impossible. 

Another aspect is performance. Many of the solutions have overhead that makes builds or development slow. The instructions here aim for the most performant system possible with docker. 

## Assumptions

Currently, it is assumed that you are working in Scientific Linux 6 (this is the OS that Muon g-2 and NOvA use) and you are accessing executables and libraries with the [CernVM Filesytem (CVMFS)](https://cernvm.cern.ch/portal/filesystem). CVMFS is an extremely efficient and flexible system for delivering up to date dependencies to your development environment. By caching only the files you actually use, your experiment's dependencies will have the smallest footprint on your system possible. CVMFS allows one docker image to be useful for many development projects. 

## Details

* For best performance, `/cvmfs` is mounted and managed from within the container (mounting the Mac's CVMFS within the container performs very poorly).
* You will keep your development and code directories and files on your Mac file system. The container will need performant access to that filesystem. We will use `nfs` (transparently to you) to do that. An advantage here is that you may be able to use nice Mac-based IDEs for development (e.g. see [CLion for the Mac](clion-mac.md)).  
* You may use one of several different "styles" of use for the container
  * Run the container as a full service that hosts VNC and access like a Linux desktop. The container needs to be up and running during use. 
  * Run the container as a build/execution service for an IDE like CLion. In this case, the container needs to be up and running during use.
  * Run the container from the command line. In this case you can `docker run` various commands within the container.

## Installation

These instructions will guide you through installing the containers and associated files.

### Install and prepare Docker for Mac

You need to install and configure `docker` on your Mac. Go to https://www.docker.com/products/docker-desktop and click on "Download Desktop for Mac and Windows". Then click on "Download Docker Desktop for Mac". If given a choice, choose the "stable" edition and not "edge". The latter is a preview version and I've found that to be unstable. You can then skip the rest of the tutorial on the web site. 

Docker for Mac is a service that runs on your Mac all the time in order to support and run Docker containers. You should see a little "whale" icon in your menu bar. Click on that and select `Preferences`. I leave the main preferences page as the default. Select `File Sharing`. This screen shows what top level directories you want to share with docker containers. If you plan to run CLion on the Mac as described [here](clion-mac.md), then you need to add directories to make it look like the following,

![File Sharing preferences](documentation/filesharing.png)

If you do not plan to run CLion, then you can leave the default. 

Next, click on the `Advanced` tab. I allow Docker to access half of my Mac laptop's threads (I have 6 CPUs and 12 hyper-threads) and half of the machine's memory. See below.

![Advanced preferences](documentation/advanced.png)

You can tailor these preferences to your liking. Leave the subnet as the default. If you make changes, you must click "Apply & Restart".

Next, click on `Daemon`. By default, docker will allow containers serving network ports to accept incoming connections from outside of your laptop. In general, this is a security problem and could lead to your Mac being blocked on the Fermilab network if the lab security scanner detects an accessible open port into, say, a web service hosted by a container. You can restrict docker to only accept connection from your Mac itself by changing the configuration as shown (in particular, the `ip` setting). 

![Daemon preferences](documentation/daemon.png)

This setting eliminates the possibility of a security problem with docker. 

If you've made any changes, click on "Apply & Restart". 

Note that you can make your life easier with bash command completion. See [here](https://docs.docker.com/compose/completion/) for how to install that. Follow the Mac instructions. 

### Prepare NFS on your Mac

For the best performance, your `/Users` directory will be served by your Mac into the docker container with `nfs`. I have found this technique to be the most performant way to access data on the Mac from the container. It is a little complicated to set up, so we'll do it only for the directory that matters - that is where all your code files exist in `/Users`. To do this, you need to follow these steps from a Mac terminal:

First - determine your user and group id numbers. Record them somewhere. 
```bash
id -u  # User ID
id -g  # Group ID
```

Now, edit the `/etc/exports` file with `sudo emacs -nw /etc/exports` from the Mac terminal. You may need to enter your password for the `sudo` to work. Add a line like the following...

 ```
/Users -alldirs -mapall=502:20 -no_subtree_check -async localhost
```
 
 Be sure to replace the `502` with your user ID and the `20` with your group ID. Note that the `localhost` means your files will not be exported outside of your laptop, so this is safe. Save with `Ctrl-x Ctrl-c`. 
 
 Now, edit `/etc/nfs.conf` with `sudo emacs -nw /etc/nfs.conf`. Add the following line,
 ```
nfs.server.mount.require_resv_port = 0
```

and save with `Ctrl-x Ctrl-c`.

This option means (from the man page):

> nfs.server.mount.require_resv_port: 
                This option controls whether MOUNT requests are required to
                originate from a reserved port (port < 1024).  The default value
                is 1 (yes).  Many NFS server implementations require this
                because of the false belief that this requirement increases
                security.

Now, restart nfs with 
```bash
sudo nfsd restart
```

Finally, restart docker. Click on the whale symbol in the menu bar and select `Restart` from the menu. 

You can learn more about this configuration at this [blog post](https://medium.com/@sean.handley/how-to-set-up-docker-for-mac-with-native-nfs-145151458adc). 

## The docker images

There are five docker images you may pull or build (note that all of the images have `lyonfnal/` in front). 

* `devenv:sl6` Scientific Linux 6 base image (970 MB). Includes SL6 with packages needed for development.
* `devenv_cvmfs:sl6` Above as base with CVMFS (400 MB more than base). Allows one to mount CVMFS. Three cvmfs directories are mounted, 
  * `/cvmfs/config-osg.opensciencegrid.org`
  * `/cvmfs/fermilab.opensciencegrid.org`
  * `/cvmfs/"${CVMFS_EXP}".opensciencegrid.org` where `$CVMFS_EXP` is an environment variable with the experiment repository name like `nova` or `gm2`
  * If you need more repositories mounted, then make a pull request or open an issue. 
* `devenv_cvmfs_vnc:sl6` Above as base with VNC and desktop packages (500 MB more than base). Allows one to run VNC and have a desktop linux experience. 
* `devenv_cvmfs_nfsserver:sl6` A special image where the container can serve CVMFS directories to other containers via nfs. 
* `devenv_cvmfs_nfsclient:sl6` A image like `devenv_cvmfs:sl6` but it mounts CVMFS via nfs served by a container from the image above. 

## Which image to use?

The following use cases are instructive for deciding which image to use. 

`devenv:sl6` is pretty useless on its own because it does not have CVMFS. It serves to be a base image for others. 

`devenv_cvmfs:sl6` may be your main workhorse. A container from this image will start CVMFS on launch. Mounting CVMFS can take a minute or two. This overhead is acceptable if you plan to launch the container rarely. If you build and run code from the command line in the same session, that will be fine. The CLion for Mac integration can use `docker exec` to run commands in such a long-lived container. 

The usage pattern involving `devenv_cvmfs:sl6`, that is running it as a long-lived container (like a service or a remote machine), is not really the *docker way*. The *docker way* is to spin up the container quickly, run a particular command, and exit the container (e.g. with `docker run`). The long startup time for mounting CVMFS makes this *docker way* usage pattern difficult. The workaround is to have a long lived service that mounts CVMFS and serves it to ephemeral containers that can start very quickly. A container from the  `devenv_cvmfs_nfsserver:sl6` image is the long lived CVMFS service. Containers of the `devenv_cvmfs_nfsclient:sl6` image are the ephemeral ones that run a particular command. They mount CVMFS from the service via nfs, which is very fast. Furthermore, you can run two or more such containers simultaneously with the same CVMFS cache. The main use case here is to accommodate Mac applications that can work with docker, but insists on starting their own containers. 

Finally `devenv_cvmfs_vnc:sl6` makes a long lived container that mounts CVMFS and then runs VNC, giving you a full linux desktop experience. This can be useful for running linux GUI applications. VNC tends to be **much** faster than running graphics applications from forwarded X windows. You can also run openGL applications in VNC (though docker does not have access to your GPU, so it will be software 3D rendering).


### I still don't know which image to use

Use `devenv_cvmfs:sl6` for a long lived container that mounts CVMFS itself. 

## Running the containers with `docker-compose`

To run the containers with `docker run` would require many, many options to the command to set up the container correctly. It is much easier to run the container from [docker-compose](https://docs.docker.com/compose), which stores the configuration in a file. You may also run the container as a service (this is important for running VNC and using CLion). 

### Setting up `docker-compose`

You are likely wanting to run the container for a development purpose. Make a directory on your Mac for a development area. For example, I may choose `/Users/lyon/Development/gm2/laserCalib`. In that directory, make a `docker` sub-directory.

Now copy the `docker-compose.yml-TEMPLATE` file from this repository. You may either check out the repository or download the file directly from [here](https://github.com/lyon-fnal/devenv/tree/master/compose). 

Follow the instructions in the comments and replace the parts of the template.  There are some notes to uncomment certain parts if you plan to use CLion for the Mac (see [here](clion-mac.md)). You can do that now or later after setting things up (again, see below).

### Notes about `docker-compose`
Docker compose works like `vagrant`. `docker-compose` commands will look in the current directory for the `docker-compose.yml` configuration file.  This can be quite convenient. If you would rather operate out of a different directory, you can always add the `-f FILE` option and give the location of the file. For example,
```bash
docker-compose -f ../docker/docker-compose.yml ...   # if you aren't in the directory with the docker-compose.yml file
```

For the instructions below, we'll assume that you are in the directory with the `docker-compose.yml` file. 

Also, you need to be a little careful about where you put options on the command line. In general, the form of a `docker-compose` command is,

```bash
docker-compose <COMMAND> <COMMAND-OPTIONS> <SERVICE> <SERVICE-OPTIONS>
```

For example, this works
```bash
docker-compose run --rm --entrypoint /bin/bash devenv-laserTest "-c runMyScript.sh"
```

The `--rm` and `--entrypoint` options are for the `run` docker-compose command. The `-c runMyScript.sh` option is passed to the container when it launches.  Moving those options around will fail. For example, this will not work...

```bash
docker-compose --rm run  devenv-laserTest --entrypoint /bin/bash "-c runMyScript.sh"  # FAILS
```

### Features of  `docker-compose.yml` file

The docker-compose configuration file defines several services. `<NAME>` is the name you chose, such as the development area name

* `devenv-<NAME>`: Service makes a long lived container from the `lyonfnal/devenv_cvmfs:sl6` image that mounts CVMFS at launch.

* `devenv-vnc-<NAME>`: Service makes a long lived container from the `lyonfnal/devenv_cvmfs_vnc:sl6` image that mounts CVMFS and runs VNC.

* `cvmfs_nfs_server`: Service makes a long lived container from the `lyonfnal/devenv-cvmfs-nfsserver:sl6` image that mounts CVMFS and serves it via nfs for the client container (next).

* `devenv-client-<NAME>`: Service makes a container from the `lyonfnal/devenv-cvmfs-nfsclient:sl6`. The container will launch very quickly and will exit when the command completes. It is not long lived. 

For each service, the `docker-compose.yml` file defines environment variables, mounted volumes, security settings, and port mapping. 

## Running 

Below are instructions for running the services in the `docker-compose.yml` file. In general, you will choose to run **either** the long lived container (CVMFS is launched by the container - simpler) or ephemeral containers (CVMFS is served by the `cvmfs_nfs_server` container - less simple).

### Run a long lived container
 
The long lived services mount CVMFS and, perhaps, start VNC, and then wait to be killed. You will "exec" into the container to do work ("exec" will launch a command like `bash` in an already running container). In general, you start the service with 

```bash
docker-compose up -d <SERVICE>
```

where `<SERVICE>` is the service you want to start. If you leave that off, all of the services in the file will be started, and you likely don't want that. 

Here's an example,
```bash
docker-compose up -d devenv-test
```

Many of the services take awhile to start. You can look at progress with

```bash
docker-compose logs -f <SERVICE>
```
 
Type Ctrl-C to exit out of the log viewer. The service will continue run.

To stop all services, do 
```bash
docker-compose down
```

To get a bash shell prompt from an "up" service, use `docker-compose exec`. For example,
```bash
docker-compose exec <SERVICE> /bin/bash
``` 
Exiting from that shell does **NOT** stop the service. You can `docker-compose exec` again. 

To start a service to the prompt **without** initializing (this is not typical and is used to debug the image),
```bash
docker-compose run --rm --entrypoint /bin/bash <SERVICE>  # Not typical to run this way
``` 
The startup script will not run, and so CVMFS will not be mounted and VNC (if appropriate) will not run.

### Running ephemeral containers 

The ephemeral containers are those run by the `devenv-client-<NAME>` service that makes containers from the `devenv_cvmfs_nfsclient:sl6` image. These containers launch very quickly, mount CVMFS from nfs (very fast), run a command, and exit. 

Before you launch such containers, the `cvmfs-nfs-server` container must be running, since it serves CVMFS to the ephemeral client containers. Start it with

```bash
docker-compose up -d cvmfs-nfs-server
docker-compsoe logs -f cvmfs-nfs-server  # Wait for startup

# Stop the service much later
docker-compose down
```

You can then run the ephemeral client containers with 
```bash
docker-compose run --rm devenv-client-<NAME> command

# Example
docker-compose run --rm devenv-client-mydev mrb b
```

The ephemeral containers will likely need some environment setup. The best way to do that is with an environment file. See the appropriate section in the [CLion for Mac](clion-mac.md#capture-your-development-environment-to-an-env-file) instructions for an example. 

### Some notes

This `docker-compose` configuration template is not really set up to run containers from different development areas simultaneously. If you try this, you may need to change the host port numbers or use ephemeral ports to avoid conflicts. You should not run more than one `cvmfs_nfs_server` container as all such server containers share the same cache volume.  You can certainly change the compose file to suit your needs (e.g. remove services you'll never use).

You may want to have one `docker-compose.yml` file for your entire development setup (e.g. not make one per development area). That would allow you to run more containers simultaneously with changes to the file. Furthermore, all containers defined by one `docker-compose.yml` file are on the same "docker network", and therefore you can run one `cvmfs_nfs_server` container. If you have nfs client containers from *different* `docker-compose.yml` files, you will need to create a common docker network and specify that in the container configuration. One `docker-compose.yml` file eliminates that problem. This use case is beyond the scope of this document, but open an issue for help. 

### Connecting to the container with VNC

You may run a full Linux desktop with VNC. You must us the `denenv-vnc-<NAME>` service in the `docker-compose.yml` file as per above. Your Mac comes with a VNC-viewer called `Screen Sharing`. Bring up `Screen Sharing` (you can use "Spotlight Search" by Command-Space and search for it or from the Finder in `Macintosh HD -> System -> Library -> CoreServices -> Applications -> Screen Sharing`). In the "Connect To" box type `localhost:5901` (you'll note that the 5901 port is specified in the `docker-compose.yml` file). The VNC password is `devenv`. You may see a warning about running as the Superuser. You can ignore it. I like to maximize the Screen Sharing window (green expand button on the  upper left). On the top menu bar, the right most icon that looks like a terminal will open a terminal window.  
 
 You can change the desktop screen size with `System -> Preferences -> Display`. I use 2880x1800 when connected to a big screen and 1920x1200 when on my laptop proper. 
 
 This is a full-featured X11 desktop. You can run Root and other programs including those needing OpenGL (note that 3D software rendering is employed - docker does not have access to your GPU). 
 
 Note that you can quit Screen Sharing and restart it - your session will continue as it was. Stopping the service with `docker-compose down` will end your session. 
 
## Doing stuff

The container should have the tools you need to do what you want. You can set up `mrb`, run `art` code, run `root`, etc. You can install linux software on your Mac volume and run it from the container (I used to run Linux CLion this way). If there's a basic tool or program you want included in the container, make a pull request to the Github repository. 

### Examining container resource usage with `netdata`

The `netdata` server program is included in the image. You can run it in a long lived container by typing `netdata` at a shell prompt within the container. There will be no response. You may then use your Mac web browser (e.g. Safari) and go to `localhost:19998`. You can then explore nearly endless aspects of what the container is doing. 

### Running CLion

See [clion-linux.md](clion-linux.md) for running CLion under Linux within the container. See [clion-mac.md](clion-mac.md) for running CLion under the Mac using a `devenv` container.  

 
 
