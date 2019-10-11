# devenv - A developmemt environment for the Mac
Adam L. Lyon, October 2019

## Introduction
Linux style development, like what we do for particle physics experiments at Fermilab, is becoming more difficult on the Mac. Apple is moving to its own style of development that is often incompatible. For example,
* System Integrity Protection (SIP) prevents using `DYLD_LIBRARY_PATH`, breaking the mechanism used by our development environment system, `ups`.
* Mac headers and system libraries are not always compatible with those on Linux, necessitating platform dependent code.
* XCode is more focused on Swift, Objective-C, and Mac or iOS-style development. XCode does not understand CMake builds natively. 

The differences that Mac and XCode introduce are difficult to manage and many experiments have stopped making Mac builds. Despite these problems, Mac laptops remain powerful machines and the MacOS environment is advantageous in many other areas. Therefore, mitigating the problems with Linux style development is motivated.

This package contains a configuration for `docker` containers along with instructions for integrating with the Mac that make for an effective and efficient development platform for Linux style development of physics code. Instructions for using CLion for C++ development in this environment are also given.  

Note that the containers and techniques here may also work on Windows. You will have to adapt these instructions for that platform. 

## Details

* For best performance, `/cvmfs` is mounted and managed from within the container (mounting the Mac's CVMFS within the container performs very poorly).
* You will keep your development and code directories and files on your Mac file system. The container will need performant access to that filesystem. We will use `nfs` to do that. An advantage here is that you may be able to use nice Mac-based IDEs for development.  
* You may use one of several different "styles" of use for the container
  * Run the container as a full service that hosts VNC and access like a Linux desktop. The container needs to be up and running during use. 
  * Run the container as a build/execution service for an IDE like CLion. In this case, the container needs to be up and running during use.
  * Run the container from the command line. In this case you can `docker run` various commands within the container. But see below. 
  
One difficulty is that most of our physics code requires a setup step before running or building, which may be time consuming. We will try a mitigation for CLion. 

## Why Docker containers?

There are three ways to do Linux style development on the Mac

1. Not do it - that is conform to the Mac development style. As discussed above, this solution is becoming too difficult and costly to maintain.
1. Run a Linux virtual machine with [Virtual Box](https://www.virtualbox.org) and [vagrant](https://www.vagrantup.com). A Virtual Box Linux VM is a heavyweight virtualization solution that is complicated to set up and maintain. `vagrant` makes configuration and management easier though not simple. Virtual Box VMs are also difficult to distribute. One advantage here is that Mac IDEs that support remote development do so with `ssh`, which is the preferred way to interact with a VM. 
1. Run a Linux Docker Container. [Docker](https://www.docker.com) containers are lightweight virtualization solutions, relatively easy to set up and configure and are portable to other systems that run Docker or [Singularity](https://sylabs.io). A disadvantage is that running `ssh` in the container is not the "docker way", therefore integration with remote development capable IDEs is more difficult, but not impossible. 

Another aspect is performance. Many of the solutions have overhead that makes builds or development slow. The instructions here aim for the most performant system possible with docker. 


## Installation

These instructions will guide you through installing the containers and associated files.

### Install and prepare Docker for Mac

You need to install and configure `docker` on your Mac. Go to https://www.docker.com/products/docker-desktop and click on "Download Desktop for Mac and Windows". Then click on "Download Docker Desktop for Mac". If given a choice, choose the "stable" edition and not "edge". The latter is a preview version and I've found that to be unstable. You can then skip the rest of the tutorial on the web site. 

Docker for Mac is a service that runs on your Mac all the time in order to support and run Docker containers. You should see a little "whale" icon in your menu bar. Click on that and select `Preferences`. I leave the main preferences page as the default. Select `File Sharing`. This screen shows what top level directories you want to share with docker containers. If you plan to run Clion (see below), then you need to add directories to make it look like the following,

![File Sharing preferences](documentation/filesharing.png)

If you do not plan to run CLion, then you can leave the default. 

Next, click on the `Advanced` tab. I allow Docker to access half of my Mac laptop's threads (I have 6 CPUs and 12 hyper-threads) and half of the machine's memory. See below.

![Advanced preferences](documentation/advanced.png)

You can tailor these preferences to your liking. Leave the subnet as the default. If you make changes, you must click "Apply & Restart".

Next, click on `Daemon`. By default, docker will allow containers serving network ports to accept incoming connections from outside of your laptop. In general, this is a security problem and could lead to your Mac being blocked on the Fermilab network if the lab security scanner detects an accessible open port into, say, a web service hosted by a container. You can restrict docker to only accept connection from your Mac itself by changing the configuration as shown (in particular, the `ip` setting). 

![Daemon preferences](documentation/daemon.png)

This setting eliminates the possibility of a security problem with docker. 

If you've made any changes, click on "Apply & Restart". 

### Prepare NFS

For the best performance, your `/Users` directory will be served into the docker container with `nfs`. I have found this technique to be the most performant way to access data on the Mac from the container. It is a little complicated to set up, so we'll do it only for the directory that matters - that is where all your code files exist in `/Users`. To do this, you need to follow these steps from a Mac terminal:

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

There are three docker images you may pull or build.

* `devenv:sl6` Scientific Linux 6 base image (970 MB). Includes SL6 with packages needed for development.
* `devenv_cvmfs:sl6` Above as base with CVMFS (400 MB more than base). Allows one to mount CVMFS. Three cvmfs directories are mounted, 
  * `/cvmfs/config-osg.opensciencegrid.org`
  * `/cvmfs/fermilab.opensciencegrid.org`
  * `/cvmfs/"${CVMFS_EXP}".opensciencegrid.org` where `$CVMFS_EXP` is an environment variable with the experiment repository name like `nova` or `gm2`
  * If you need more repositories mounted, then make a pull request or open an issue. 
* `devenv_cvmfs_vnc:sl6` Above as base with VNC and desktop packages (500 MB more than base). Allows one to run VNC and have a desktop linux experience. 

### Pulling the images

You can pull the images directly from [Docker Hub](http://hub.docker.com). The first image, `devenv:sl6`, is somewhat useless on its own as most of our physics code relies on CVMFS. It is best to pull one or both of the other images. 

If you never plan to use VNC, then,
```bash
docker pull lyonfnal/devenv_cvmfs:sl6
```

If you plan to use VNC all the time, then
```bash
docker pull lyonfnal/devenv_cvmfs_vnc:sl6
```

Otherwise, just do both. It only takes about 2 GB on your disk.
```bash
docker pull lyonfnal/devenv_cvmfs_vnc:sl6 
docker pull lyonfnal/devenv_cvmfs:sl6  # This won't actually download anything 
```
The second pull won't download anything because `devenv_cvmfs:sl6` is the base image for `devenv_cvmfs_vnc:sl6`.

You need `devenv_cvmfs:sl6` if you use CLion on the Mac (see below). 

### Building the images

You may build the images yourself instead of pulling from Docker hub. This will take a significant amount of time and requires a fast internet connection.  You should only do this if you want to make a change to a image. Better is to make a pull request and I can make your change in the repository. But if you really want to do the build yourself, you can do the following. Note that you may want to use a different identifier than `lyonfnal`. If you do that, you'll need to change the `FROM` declarations in each `Dockerfile`. 

If you want to build the images as they are, then do the following

```bash
# Only if really necessary (prefer pull instead)
cd Somewhere
git clone https://github.com/lyon-fnal/devenv.git
cd devenv
cd devenv_sl6 ; docker build -t lyonfnal/devenv:sl6 . ; cd ..
cd devenv-cvmfs_sl6 ; docker build -t lyonfnal/devenv_cvmfs:sl6 . ; cd ..
cd devenv-cvmfs-vnc_sl6 ; docker build -t lyonfnal/devenv_cvmfs_vnc:sl6 . ; cd ..
```

## Running the containers with `docker-compose`

To run the containers with `docker run` would require many, many options to the command to set up the container correctly. It is much easier to run the container from [docker-compose](https://docs.docker.com/compose), which stores the configuration in a file. You may also run the container as a service (this is important for running VNC and using CLion). 

### Setting up `docker-compose`

You are likely wanting to run the container for a development purpose. Make a directory on your Mac for a development area. For example, I may choose `/Users/lyon/Development/gm2/laserCalib`. In that directory, make a `docker` sub-directory.

Now copy the `docker-compose.yml-template` file from this repository. You may either check out the repository or download the file directly with [this url](https://raw.githubusercontent.com/downloads/lyonfnal/devenv/compose/docker-compose.yml-template). 

Follow the instructions in the comments and replace the parts of the template. The `sed` command in the comments may make things easier. There are some notes to uncomment certain parts if you plan to use CLion (see below). You can do that now or later after setting things up (again, see below).

### A note about `docker-compose`
Docker compose works like `vagrant`. `docker-compose` commands will look in the current directory for the `docker-compose.yml` configuration file.  This can be quite convenient. If you would rather operate out of a different directory, you can always add the `-f FILE` option and give the location of the file. For example,
```bash
docker-compose -f ../docker/docker-compose.yml ...   # if you aren't in the directory with the docker-compose.yml file
```

For the instructions below, we'll assume that you are in the directory with the `docker-compose.yml` file. 

### The `docker-compose.yml` file

Instructions above explain how to set up the `docker-compose.yml` file from the template. Here are some features of this configuration file.

The `docker-compose.yml` file defines a configuration for running a docker container. Such a file is easier than figuring out the myriad of options you would need to `docker run`. The `docker-compose` system allows you to treat the container as a service running in the background. 

The top part of the file defines which image to run and what the container should be called. The name of the container `<NAME>` should be something related to your development task, like `laserCalibDB`. The host name in the container is also set to this name so that a shell in that container is easily identifiable. 

Privilege settings are defined. To run CVMFS and `gdb`, the container must be launched with expanded security settings.

Next, several port mappings are made. They are all bound to the local host (`127.0.0.1`) just in case you didn’t change the docker configuration to make that the default. If you aren’t using a particular port, it’s ok to leave the mapping in place. 

Next are two lines commented out involving `env` and `build.env`. That’s for injecting environment variables into the container. We will use that later to quickly start a shell in the container. 

Much of the remainder of the file is for defining volumes. One of the main volumes is called `workdir` (you never see these volume names in the container). You’ll see towards the bottom that `workdir` is your Mac user area mounted via `nfs` for performance. The default is to mount `/Users/<USER>` (for example, `/Users/lyon`). The volume is mounted such that it has the same path in the container as it has on the Mac. This has many advantages when running an IDE on the Mac side. Note that you can restrict the directory mounted by putting that in `<USER>`, such as `lyon/Development/gm2/myDevArea`. My experience is that it is better to just mount the top level user directory. 

The `cvmfs_cache` volume is the cvmfs cache area. Making this an external volume, as is done here, means the data is retained  when the container exits. This means that you do not need to repopulate the cache when you stop the container and start it again later. 

Similarly, it is nice for the home area in the container to be retained from runs of the container. Making `/root` come from an external volume (`slash_root`) does that. 

Finally, there are a few mounts from the Mac side that are necessary if you plan to run CLion. Those are mounted with the standard less than performant Docker mechanism since high performance is not needed there. 


 ### Run with `docker-compose run` [not typical]
 
 If you simply want to start the container and get a shell prompt and have the container exit when you are finished (e.g. not run it as a service - this is **not the typical way** to run the container), you can do,
 
 ```bash
cd /path/to/docker-compose-directory
docker-compose run --rm --entrypoint /bin/bash <NAME>
#   where <NAME> is the service name you chose when making the docker-compose.yml file

# Now inside the container...
/usr/local/bin/start_cvmfs.sh  # if you want CVMFS mounted
# ... do stuff ...
exit  
# Container exits and is removed (external volumes stay)
```
 
 When you exit out of the container shell, the container exits and is removed.
 
 ### Run as a service with `docker-compose up -d` [do this]
 
 The typical way to run the container is as a service (this is advantageous as it takes time to mount `/cvmfs`), either with or without VNC (you made that choice when you created `docker-compose.yml` from the template). To start, do
 
 ```bash
cd /path/to/docker-compose-directory
docker-compose up -d    # -d is for daemon mode
docker-compose logs -f  # Watch CVMFS start up - takes a minute or two
```

The log will end with "Running until killed" or information about VNC. You can then `Ctrl-C` out of `docker-compose log`. The service will continue to run in the background. 

To stop the container and take down and remove the service, do
```bash
cd /path/to/docker-compose-directory
docker-compose down
```

Note that the data in the external volumes are retained. 

### Connecting to the container with VNC

You may run a full Linux desktop with VNC. You must specify the `lyonfnal/devenv_cvmvs_vnc:sl6` image in the `docker-compose.yml` file and start the container as a service as per above. Your Mac comes with a VNC-viewer called `Screen Sharing`. Bring up `Screen Sharing` (you can use "Spotlight Search" by Command-Space and search for it or from the Finder in `Macintosh HD -> System -> Library -> CoreServices -> Applications -> Screen Sharing`). In the "Connect To" box type `localhost:5901` (you'll note that the 5901 port is specified in the `docker-compose.yml` file). The VNC password is `devenv`. You may see a warning about running as the Superuser. You can ignore it. I like to maximize the Screen Sharing window (green expand button on the  upper left). On the top menu bar, the right most icon that looks like a terminal will open a terminal window.  
 
 You can change the desktop screen size with `System -> Preferences -> Display`. I use 2880x1800 when connected to a big screen and 1920x1200 when on my laptop proper. 
 
 This is a full-featured X11 desktop. You can run Root and other programs including those needing OpenGL (note that 3D software rendering is employed - docker does not have access to your GPU). 
 
 Note that you can quit Screen Sharing and restart it - your session will continue as it was. Stopping the service with `docker-compose down` will end your session. 
 
 ### Connecting to the container without VNC (shell)
 
 If I am running CLion on my Mac and connecting to the container, I do not need VNC. Therefore I run the image without it. Follow the same instructions as *Run as a service* above. 
 
 With the service running in the background, you can connect to a shell within with,
 
 ```bash
docker-compose exec <NAME> /bin/bash
```
where `<NAME>` is the name of the service you chose when you made the `docker-compose.yml` file. You will then have a fresh shell at the root prompt. CVMFS will be mounted already. 

You may exit this shell back to your Mac. The service will continue to run. You may `docker-compose exec` in again.

You may stop the service completely with `docker-compose down` as explained above. 

## Doing stuff

The container should have the tools you need to do what you want. You can set up `mrb`, run `art` code, run `root`, etc. You can install linux software on your Mac volume and run it from the container (I used to run Linux CLion this way). If there's a basic tool or program you want included in the container, make a pull request to the Github repository. 

### Examining container resource usage with `netdata`

The `netdata` server program is included in the image. You can run it by typing `netdata` at a shell prompt within the container. There will be no response. You may then use your Mac web browser (e.g. Safari) and go to `localhost:19998`. You can then explore nearly endless aspects of what the container is doing. 


 
 
