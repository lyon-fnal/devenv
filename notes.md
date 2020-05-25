<span style="font-size:3em;">Notes</span>

This file has notes so that the author doesn't forget stuff.

- [1. Troubleshooting startup of containers](#1-troubleshooting-startup-of-containers)
- [2. Underscores vs. dashes problem](#2-underscores-vs-dashes-problem)
- [3. Running only the ephemeral client](#3-running-only-the-ephemeral-client)
- [4. SL7 containers](#4-sl7-containers)
- [5. VSCode gives an error when using a Docker container](#5-vscode-gives-an-error-when-using-a-docker-container)

# 1. Troubleshooting startup of containers

If a container isn't starting properly, you can start it without the `entrypoint` running with, for example, 

```bash
docker-compose run --rm --entrypoint=/bin/bash devenv-client-v936
```

Note that the `--entrypoint` option must be *before* the container or service name. If it goes after, it'll be ignored causing confusion. 

# 2. Underscores vs. dashes problem

There is a method to my madness that fails badly at one point.

I tried to use underscores for names of things that are "real", like images and disk volume names. 

I tried to use dashes for names that are symbols, like directory names and service names. 

This idea fails for `cvmfs_nfs_server`. I would like to call the service `cvmfs-nfs-server` (dashes instead of underscores) but that doesn't work because despite specifying the hostname of the container to be `cvmfs_nfs_server`, docker uses the service name in creating the **network name** of the container. So since the client is looking to mount CVMFS volumes from `cvmfs_nfs_server` and the host name is named as such, because the service name in the compose has dashes the network name has dashes and it can't be found. Maybe there's a way to override this. According to https://stackoverflow.com/questions/29924843/how-do-i-set-hostname-in-docker-compose, there is a way to override, but it's complicated. The fact that the hostname is not the network name is a known issue (see the link).   

# 3. Running only the ephemeral client

I like to only run the ephemeral client. But when I create a `docker-compose.yml` file from the template and try to run the `cvmfs_nfs_server` container, I get a message about creating the volume for the long lived client that I don't want. Just remove that from the `volumes` section and remove the long-lived services.  

# 4. SL7 containers

I'm only making the `devenv-cvmfs:sl7` container. The VNC container doesn't work with SL7 due to DBus problems that I don't understand.
I may try the NFS containers later, but I have a feeling that getting NFS to run in SL7 is going to be another round of problems. And I'm not sure that I really need the NFS containers to do my work. 

# 5. VSCode gives an error when using a Docker container

I've seen instances of VSCode throwing errors when using a docker container. This seems to happen when a configuration file gets corrupted (not sure why this happens). Try to attach back into the running docker container and from the palette (Command-Shift-P) choose `Remote-Containers: Open Container Configuration File`. Fix any corruption you see and save. Then try the operation that caused the error again. It should work now. 