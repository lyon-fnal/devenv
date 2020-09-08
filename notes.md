<span style="font-size:3em;">Notes</span>

This file has notes so that the author doesn't forget stuff.

- [1. Troubleshooting startup of containers](#1-troubleshooting-startup-of-containers)
- [2. VSCode gives an error when using a Docker container](#2-vscode-gives-an-error-when-using-a-docker-container)

# 1. Troubleshooting startup of containers

If a container isn't starting properly, you can start it without the `entrypoint` running with, for example,

```bash
docker-compose run --rm --entrypoint=/bin/bash devenv-thename
```

Note that the `--entrypoint` option must be *before* the container or service name. If it goes after, it'll be ignored causing confusion.

# 2. VSCode gives an error when using a Docker container

I've seen instances of VSCode throwing errors when using a docker container. This seems to happen when a configuration file gets corrupted (not sure why this happens). Try to attach back into the running docker container and from the palette (Command-Shift-P) choose `Remote-Containers: Open Container Configuration File`. Fix any corruption you see and save. Then try the operation that caused the error again. It should work now.
