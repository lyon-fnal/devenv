# Notes

This file has notes so that the author doesn't forget stuff.

## Troubleshooting startup of containers

If a container isn't starting properly, you can start it without the `entrypoint` running with, for example, 

```bash
docker-compose run --rm --entrypoint=/bin/bash devenv-client-v936
```

Note that the `--entrypoint` option must be *before* the container or service name. If it goes after, it'll be ignored causing confusion. 

## Underscores vs. dashes problem

There is a method to my madness that fails badly at one point.

I tried to use underscores for names of things that are "real", like images and disk volume names. 

I tried to use dashes for names that are symbols, like directory names and service names. 

This idea fails for `cvmfs_nfs_server`. I would like to call the service `cvmfs-nfs-server` (dashes instead of underscores) but that doesn't work because despite specifying the hostname of the container to be `cvmfs_nfs_server`, docker uses the service name in creating the **network name** of the container. So since the client is looking to mount CVMFS volumes from `cvmfs_nfs_server` and the host name is named as such, because the service nane in the compose has dashes the network name has dashes and it can't be found. Maybe there's a way to override this. According to https://stackoverflow.com/questions/29924843/how-do-i-set-hostname-in-docker-compose, there is a way to override, but it's complicated. The fact that the hostname is not the network name is a known issue (see the link).   

## Running only the ephemeral client

I like to only run the ephemeral client. But when I create a `docker-compose.yml` file from the template and try to run the `cvmfs_nfs_server` container, I get a message about creating the volume for the long lived client that I don't want. Just remove that from the `volumes` section and remove the long-lived services.  