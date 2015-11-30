# nwn-devbase
This repository is meant to function as a base setup for anyone who wants to version control their module development for the game Neverwinter Nights (NWN), using git. It also contains instructions for setting up a local test environment using Docker, which can easily be distributed to the development team.

In addition, the texts here are meant to function as a reference for users unfamiliar with git and Docker, as is the case with some of my team members. [INTRODUCTION](https://github.com/jakkn/nwn-devbase/blob/master/INTRODUCTION.md) introduces the problem areas git and Docker solve, and attempts to explain how the development process is supposed to work. It also presents an overview of how the systems are wired together.


## But seriously, what's the point?
Can't people just version control their sources without this? Of course they can. However, it is not a straight forward process. The Aurora Toolset stores all module content in file archives with the *.mod* extension. git does not handle *.mod* archives, so for git to be of any use the archive must first be unpacked. The process of unpacking and repacking module content may be cumbersome to some, which is why I have created this repository. It is an attempt at sharing the work I have done so that anyone who may want to do the same can do so with minimal effort. The basis for this work is what I have already done on an existing server - [Bastion of Peace](http://bastionofpeace.freeforums.net/).


## Intended audience
- **Admin** - Please see [SETUP](https://github.com/jakkn/nwn-devbase/blob/master/SETUP.md). It contains instructions on how to initialize version control and the local test environment.
- **Developers** - Continue reading. You will find instructions on how to initialize and use these tools below.

---

## git

First you must clone the repository. You need only do this once, and your module admin should have provided you with a link to the repository. Run `git clone <repository-url>` to clone the repository to your local computer, or clone with a gui client.

For general usage, some git basics and best practices are covered and referenced in [INTRODUCTION](https://github.com/jakkn/nwn-devbase/blob/master/INTRODUCTION.md). Using a git client like [SourceTree](https://www.sourcetreeapp.com/) or [another](https://git-scm.com/download/gui/linux) is nice if you prefer a gui, but git may also be run via the command line.

**Useful git commands**

| Function  | Command  |
| :-------------------- |:---------------------- |
| Pull latest from repo | `git pull` |
| Push local changes to repo | `git push` |
| Current status of local repo | `git status` |
| Stage a file | `git add <file>` |
| Unstage a file | `git reset HEAD <file>` |
| Commit staged files | `git commit` |
| Discard changes in working directory | `git checkout -- <file>` |


---

## ModPacker
ModPacker is used to pack and unpack the *.mod* archive. It is a Java application and needs [JRE](http://www.oracle.com/technetwork/java/javase/install-windows-64-142952.html) to run. Please make sure it is installed before proceeding.

### Usage

Run these scripts, located in *scripts/*
| OS  | Pack *src/* into *.mod* | Unpack *.mod* to *src/* |
| :-------------------- |:---------------------- |:---------------------- |
| Windows | `pack.cmd` | `unpack.cmd` |
| Linux | `pack.sh` | `unpack.sh` |

- *Symlink the packed module* to your *nwn/modules* folder in order to open the version controlled module with the Aurora Toolset.
  - Windows: `MKLINK "<path_to_nwn>\modules" "<path_to_repo>\packed\testserver.mod"`
  - Linux: `ln -s <path_to_repo>/packed/testserver.mod <path_to_nwn>/modules`

---

## Docker
When Docker runs an image it starts what is called a container. Containers are running instances of an image, and once created should be used over again to avoid unnecessary container buildup.

**Useful docker commands**

| Function  | Command  |
| :-------------------- |:---------------------- |
| List all images | `docker images` |
| List all containers | `docker ps -a` |
| Remove image | `docker rmi IMAGE` |
| Remove container | `docker rm CONTAINER` |
| Build dockerfile | `docker build .` |
| Restart container | `docker restart CONTAINER` |
| Stop container | `docker stop CONTAINER` |

### Running nwserver in a container
For the Docker container to access the module, the host directory containing the module must be mounted as a data volume in the container. This is a little tricky on OSX and Windows, as Docker runs in a VM and the directory must be shared with the VM. Instructions to come, but for now see [docker userguide](http://docs.docker.com/engine/userguide/dockervolumes/). The below example specifies a Linux path and launches the *bop-testserver:latest image*. The port specifications are necessary as Docker will not initialize UDP by default.

```
docker run -it \
  -v /home/user/nwn-devbase/packed:/opt/nwnserver/modules \
  -p 5121:5121/tcp \
  -p 5121:5121/udp \
  --name testserver \
  bop-testserver:latest
```

The procedure is similar if you need haks, overrides, or other custom files. The below example adds folders *hak*, *tlk*, and *erf*.

```
docker run -it \
  -v /home/user/nwn-devbase/packed:/opt/nwnserver/modules \
  -v /opt/nwn/hak:/opt/nwnserver/hak \
  -v /opt/nwn/tlk:/opt/nwnserver/tlk \
  -v /opt/nwn/erf:/opt/nwnserver/erf \
  -p 5121:5121/tcp \
  -p 5121:5121/udp \
  --name testserver \
  bop-testserver:latest
```

### Restarting container
The `docker run` command above creates a container named testserver and will by default run the last CMD command defined in the Dockerfile. To exit the container simply type `exit`. If nwserver launched successfully you will have to type `exit` once more, as the first command shut down the server while the second will shut down the container.

From now on you should only need the following two commands to start and stop the server.
```
docker restart testserver
docker stop testserver
```

### Connect to the server
To connect to the server from your local NWN game client, direct connect to `localhost:5121`.

### Protip
TODO: Run `pack -n` to pack the module without scripts, mount ncs folder, and use nwnx_funcs(?) to edit and test scripts without having to restart the server.


## Background
Neverwinter Nights is a RPG developed by BioWare and was released in 2001. In addition to the NWN game client, BioWare released a tool for creating custom game content, the Aurora Toolset, along with server hosting software. This enabled players to create and host their own worlds.

NWN was discontinued 7 years after release, with the final patch v1.69 released 9 July 2008. Even though the game was discontinued by the developer, the community is still strong and due to the game's hackable nature new community content is continuously released.


## Feedback
Feedback is greatly appreciated. If you have any thoughts, suggestions or ideas about how to improve the content of this project, please feel free to contact me, or even better; improve it and make a pull request.
