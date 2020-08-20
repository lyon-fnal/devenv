<span style="font-size:3em;">Visual Studio Code & Docker</span><br/>
Adam L. Lyon, May 2020

Visual Studio Code (VSCode) has a very nice *Remote Development* feature for docker containers (and `ssh` remote machines as well). Here's how I have set this up. The instructions are similar for `ssh` into a remote machine (a nice feature of this system). Note that this only works on an `SL7` docker container or machine. It does not work at all on `SL6`. 

- [1. Attaching to the container](#1-attaching-to-the-container)
- [2. Setting up the container's VSCode instance](#2-setting-up-the-containers-vscode-instance)
  - [2.1. Use a newer version of git](#21-use-a-newer-version-of-git)
  - [2.2. Add extensions to your container VSCode](#22-add-extensions-to-your-container-vscode)
- [3. Setting up the development environment](#3-setting-up-the-development-environment)
  - [3.1. Establish the development area](#31-establish-the-development-area)
  - [3.2. Set the cmake configuration](#32-set-the-cmake-configuration)
  - [3.3. Setup a toolchain](#33-setup-a-toolchain)
  - [3.4. Setup CMake build variants](#34-setup-cmake-build-variants)
  - [3.5. Script to establish the environment](#35-script-to-establish-the-environment)
- [4. Building your code](#4-building-your-code)
- [5. Running and debugging](#5-running-and-debugging)
  - [5.1 Create a `try` directory](#51-create-a-try-directory)
  - [5.2 Create an environment variable file](#52-create-an-environment-variable-file)
  - [5.3 Configure `launch.jl`](#53-configure-launchjl)
  - [5.4 Launch the debugger](#54-launch-the-debugger)

# 1. Attaching to the container

For this example, we'll use the `devenv-cvmfs:sl7` container. Create that and start it as a long-lived container with `docker-compose` as per the instructions in [README.md](README.md)). Create a directory where you want to do development on your Mac. I'll use `/Users/lyon/Development/gm2/example`. 

Start VSCode. Install the `Remote Development extension pack` (see [here](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack) for the extension and [here](https://code.visualstudio.com/docs/remote/remote-overview) for instructions). 

After installation, a green or blue square should appear at the lower left of the VSCode window. Be sure that the long-lived docker container is running. Click on the green square and choose `Remote Containers: Attach to Running Container...`  Select the correct container.

A  new window will appear with the green or blue box filled in with the container name. Everything you do in this VSCode window, including opening files, popping a terminal, etc happens in this container. 

> Note that VSCode has two modes for working with Docker containers: 1) Opening folders/workspaces/repositories in a container or 2) Attaching to a running container. I'm using the latter mode. The former mode involves VSCode mounting directories into the container using the regular Docker method, which is very non-performant. 

# 2. Setting up the container's VSCode instance

There are a few things you need to do to set up the container instance of VSCode. These are things you should only have to do once. Your home area (`/root`) in the container is an external volume, so contents will survive restarting the container. 

The first time you run, VSCode will install a Linux version of itself in `/root/.vscode-server`.
You will likely get a complaint about running an old version of `git`. Let's fix that first.

## 2.1. Use a newer version of git
The version of `git` that comes with SL7 is quite old and is incompatible with VSCode. Hopefully, your experiment has a newer git in its repository. You can have VSCode use it if you adjust your path in the `.bashrc` file.  Open `/root/.bashrc` with Command-O or menu File->Open. At the bottom, I add,

```bash
# ... stuff above here
# Use a more modern git
export PATH="/cvmfs/gm2.opensciencegrid.org/prod/external/git/v2_15_1/Linux64bit+3.10-2.17/bin":$PATH
```

Note that I'm using a version of `git` in UPS. I don't in fact have to have any environment set up to use it. 

For some reason, extensions don't always use this `git` executable. You need to also set this location in the extension configuration. Bring up preferences (Command-,) from the Remote Development window. Be sure the `Remote` tab is selected (not User). Search for `git.path` and then click on `Edit in settings.json`. Add an entry like,

```json
{
  "git.path": "/cvmfs/gm2.opensciencegrid.org/prod/external/git/v2_15_1/Linux64bit+3.10-2.17/bin/git"
}
```

Note that there may be other entries in the file. You should restart the VSCode window after this making this change (bring up the command palette with Command-Shift-P and choose `Developer: Reload Window`).

## 2.2. Add extensions to your container VSCode

We need to add some extensions to the VSCode running in the container. Click on the container icon in the sidebar. Add these extensions (if you have them installed on your local VSCode, there should be a green box you can click to install in the container)...

- C/C++
- C++ TestMate
- CMake
- CMake Tools
- Git Graph
- GitLens
- Path Intellisense

You may have to reload the window. You can do that after installing all of the extensions. 

# 3. Setting up the development environment

We'll use the `CMake tools` to set up and manage the development environment. We need to do several things

- Establish the development area
- Set the cmake configuration
- Setup a toolchain
- Setup CMake build variants
- Make a script to establish the environment

*Note:* Aside from the first step above, you can do all of the setup and building of code from the terminal command line as you normally do with `mrb`, `ninja`, etc. You don't have to integrate that with VSCode. Opening a terminal within VSCode will launch that in the container at the top level directory. 

If you want to integrate your builds with VSCode, then you'll need to do some setup as per below. You should, however, establish the development area no matter what.

## 3.1. Establish the development area

If you open a folder (directory) in VSCode, the editor treats that as a *project*. VSCode's notion of a project is rather vague, and sometimes it is called a *workspace*, but it seems to mean that the top level folder you selected can have a `.vscode` directory to specify project level configuration. The nice thing about opening a folder is that you can see the hierarchy of directories starting with the directory you selected in the file/folder explorer. 

Make a development area on your Mac filesystem and open it with Command-O (open the folder, not a file). You may see VSCode reload the window. If you see an error, see [notes.md](notes.md).

Also note that this folder will show up on the "Recent" list so you can easily connect back to the folder in the container. In fact you should use this link to reattach to the container when you come back for another session.

## 3.2. Set the cmake configuration

CMake tools needs to know where to find the `cmake` executable and you also need to set the location of the source and build directories.

Edit the file `.vscode/settings.json` in your top level project directory (create the directory and file if they aren't there) and add the following...

```json
{
    "cmake.cmakePath": "/cvmfs/gm2.opensciencegrid.org/prod/external/cmake/v3_10_1/Linux64bit+3.10-2.17/bin/cmake",
    "cmake.sourceDirectory": "${workspaceFolder}/srcs",
    "cmake.buildDirectory": "${workspaceFolder}/build_slf7.x86_64",
    "cmake.generator": "Ninja",
}
```

There may be other items in the list as well. You need to tailor the above to your configuration. You can find the location of your `cmake` executable with,
```bash
setup cmake ; which cmake
```

## 3.3. Setup a toolchain

You need to define the toolchain of compilers that CMake will use. `CMake Tools` can discover the system compilers, but not the compilers in UPS. You have to set those manually. 

To set the toolchain, bring up the palette (Command-Shift-P) and type `CMake: Edit User-Local CMake Kits`. If the configuration file does not exist, you'll be asked to do a scan. It's ok to say yes. Then the file will be in the editor. 

You'll want to add an entry for the compilers you'll be using for your build. Do not change the system compiler entries ... they'll just come back the next time a scan is done. For example, I have...

```json
[
  {
    "name": "GCC 4.8.5",
    "compilers": {
      "C": "/bin/gcc"
    }
  },
  {
    "name": "GCC for x86_64-redhat-linux 4.8.5",
    "compilers": {
      "C": "/bin/x86_64-redhat-linux-gcc"
    }
  },
  {
    "name": "gm2-sl7-v9",
    "compilers": {
        "C": "/cvmfs/gm2.opensciencegrid.org/prod/external/gcc/v6_4_0/Linux64bit+3.10-2.17/bin/gcc",
        "C++": "/cvmfs/gm2.opensciencegrid.org/prod/external/gcc/v6_4_0/Linux64bit+3.10-2.17/bin/g++",
        "Fortran": "/cvmfs/gm2.opensciencegrid.org/prod/external/gcc/v6_4_0/Linux64bit+3.10-2.17/bin/gfortran"
    },
    "environmentSetupScript":"/Users/lyon/Development/gm2/sl7/code/setupEnv.sh"
  }
]
```

Note the descriptive name of the toolchain. The `environmentSetupScript` is very important and we'll talk about that below. 

## 3.4. Setup CMake build variants

Art code can be built with one of two CMake build types: `Debug` (non-optimized with debugging symbols) and the non-standard `Prof` (optimized but with debugging symbols for profiling). Because `Prof` is non-standard, we need to tell CMake Tools about it. Make a file in the development area's `.vscode` diretory with the name `cmake-variants.yaml` and the contents of

```yaml
buildType:
  default: prof
  description: The build type
  choices:
    debug:
      short: Debug
      long: Build with debugging information
      buildType: Debug
    prof:
      short: Prof
      long: Optimized build with symbols (for profiling)
      buildType: Prof
```

## 3.5. Script to establish the environment

A very nice brand new feature of CMake Tools is that it can run a script to set up the environment before running CMake. This is absolutely crucial for UPS based development. Note the `environmentSetupScript` setting in the toolchain file above. My script, `/Users/lyon/Development/gm2/sl7/code/setupEnv.sh`, has,

```bash
#!/bin/bash

source /cvmfs/gm2.opensciencegrid.org/prod/g-2/setup

cd /Users/lyon/Development/gm2/sl7/code # Script runs out of the home area
source localProducts_gm2_v9_44_00_prof/setup
setup gdb                             # Needed for debugging
export USER=lyon                      # See below
. mrb s
```

Note that the script is run from the your home area, so you must change directory accordingly. 

The `$USER` environment variable is not set and this will cause some particular g-2 code to throw an exception. Here, I set it to my username on the `gm2gpvm` nodes. 

Note that setting up the sections above is a little flakey. You may need to disconnect from the container and reconnect for changes to get noticed. 

With this you should be all set to do builds! You should only need to do the configuration steps above once for your development area. 

# 4. Building your code

You need to run `CMake Configure` first (this is equivalent to running `cmake ...` on the command line). Bring up the command palette (Command-Shift-P) and search for `CMake: Configure`. If it asks you to select a kit, select the `gm2-sl7-v9` kit that you made earlier. VSCode may also ask    you for the location of the `CMakeLists.txt` file. It will ask you to locate it. Do that. 

If you get errors because it is running the wrong executable for CMake, disconnect from the container and reconnect. Then check the configuration and try again. 

If you change settings or the `setupEnv.sh` file, you need to reselect the toolchain for those changes to go into effect. 

You can also change the build variant (`Debug` or `Profile`) with the command palette (Command-Shift-P) and `CMake: Select Variant`. A CMake Configure will occur after your choice.

To do a build, do the command palette (Command-Shift-P) and `CMake: Build`. This will build all targets, which is typically what you want.

# 5. Running and debugging

You should run your art executable from the command line in a VSCode terminal (it will be within the container).

For debugging, you need to set some things up.

## 5.1 Create a `try` directory

The debugger wants to run from a directory. Let's make one called `try`.

```bash
cd $MRB_TOP
mkdir try
cd try
```

## 5.2 Create an environment variable file

The debugger will run in a fresh shell and, unfortunately, it will not run your environment variable file first. You can specify an environment variable file that the debugger script will load. To create this file, do

```bash
env > project.env
```

## 5.3 Configure `launch.jl`

VSCode uses a somewhat clunky mechanism to specify how the debugger is to be run. You need to create and fill in a particular file that will be in `$MRB_TOP/.vscode/launch.jl`. You can create this file with the Run menu and select "Open Configurations". You can also open the Run/Debug pane by clicking on the play symbol with the bug on the lower left; then click on "create a launch.jl file".

Select the `C++` environment and then the `Default configuration`. The `launch.jl` file will come up.

You will want to make the following changes...

- Change `name` to be a good description of the program you are debugging

- For `program`, you need the full path to your art program (e.g. `gm2` or `nova`). To get the full path, in the terminal with the environment set up, do `which gm2` (fill in your experiment's art program).
  
- For `args`, you need an element for every argument to the art program. Arguments with a parameter count as two. For example, `"args": ["-c", "QDatabaseAnalyzer.fcl", "gm2preproduction_full.root"],`

- For `cwd` you want the `try` directory, like `"cwd": "${workspaceFolder}/try",`

- Add a line for the `envFile`, `"envFile": "${workspaceFolder}/try/project.env",`. You made this in a section above.

- You also need to add a line with `miDebuggerPath` for the full debugger path since you want the one in CVMFS. You can determine the path by going to the terminal with the environment set up and doing `which gdb`. See the example below.

- If you want to break on exceptions, you need to add a section. See the example below.

Here is my `launch.json` file to debug `gm2 -c QDatabaseAnalyzer.fcl gm2preproduction_full.root` . The input file will be in the `try` directory.

```json
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "(gdb) Launch gm2 -c QDatabaseAnalyzer.fcl", // I modified
            "type": "cppdbg",
            "request": "launch",
            "program": "/cvmfs/gm2.opensciencegrid.org/specials/sl7/prod/external/art/v2_10_03/slf7.x86_64.e15.prof/bin/gm2", // I modified
            "args": ["-c", "QDatabaseAnalyzer.fcl", "gm2preproduction_full.root"], // I modified
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}/try", // I modified
            "environment": [],
            "envFile": "${workspaceFolder}/try/project.env", // I added
            "externalConsole": false,
            "MIMode": "gdb",
            "miDebuggerPath": "/cvmfs/gm2.opensciencegrid.org/specials/sl7/prod/external/gdb/v8_0_1/Linux64bit+3.10-2.17/bin/gdb", // I added
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
                {
                    // Add this part if you want to break on exceptions
                    "description": "Enable all-exceptions",
                    "text": "catch throw",
                    "ignoreFailures": true
                }
            ]
        }
    ]
}
```

## 5.4 Launch the debugger

Now set the desired breakpoints in your code. 

You can launch the debugger from the Run menu and select "Start Debugging" or from the Debugger pane by clicking on the green play triangle. Be sure to switch to the Debug Console. Be patient - the debugger will look like it is paused while it is loading symbols. It is in fact going. Eventually, you will reach your breakpoint.
