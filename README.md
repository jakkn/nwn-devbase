# nwn-devbase
This repository is meant to function as a base setup for anyone who wants to version control their module development for the game Neverwinter Nights (NWN), using git. It also contains instructions for setting up a local testing environment using Docker, which can easily be distributed to the development team.

If all you are wondering is "why", please read [OVERVIEW](https://github.com/jakkn/nwn-devbase/blob/master/OVERVIEW.md), which explains why version control and local testing environments are a good thing to have.


## What's the point?
Can't people just version control their sources without this? Of course they can, however, it is not a straight forward process. The Aurora Toolset stores all module content in file archives with the *.mod* extension. git does not handle *.mod* archives, so for git to be of any use the archive must first be unpacked. The process of unpacking and repacking module content may be cumbersome to some, which is why I have created this repository. It is an attempt at sharing the work I have done so that anyone who may want to do the same can do so with minimal effort. The basis for this work is what I have already done on an existing server - Bastion of Peace. For further details, please see [OVERVIEW](https://github.com/jakkn/nwn-devbase/blob/master/OVERVIEW.md).


## Intended audience
- **Admin** Instructions on how to set things up for the first time can be found in [SETUP](https://github.com/jakkn/nwn-devbase/blob/master/SETUP.md).
- **Developers** Instructions on how to use and run can be found below.


## git
Some git basics and best practices are covered and referenced in [OVERVIEW](https://github.com/jakkn/nwn-devbase/blob/master/OVERVIEW.md). Using a git client like SourceTree or ----TODO: add alternatives---- is nice if you prefer a gui, but git may also be run via the command line.

**Useful cli git commands**

| Function  | Command  |
| :-------------------- |:---------------------- |
| Pull latest from repo | `git pull` |
| Push local changes to repo | `git push` |
| Current status of local repo | `git status` |
| Stage file | `git add FILE` |
| Unstage file | `git checkout FILE` |
| Commit staged files | `git commit` |

Your module admin should have provided you with a link to the repository. If you have not done so already, run `git clone REPOSITORY-URL` to clone the repository to your local computer, or use a git client to do it in a gui.


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
The next steps are done in the console.

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
