# Using Docker

**Intended audience: builders**

This document covers running NWN modules in docker containers.

*Note to non-Linux users: At the time of writing there are no Windows images for nwserver, and I have no plans to make any because nwnx2-win32 is discontinued. Consequently, running nwserver in a docker container is restricted to Linux (OSX should work but is currently untested). This can be accomplished on Windows by the use of a virtual machine and sharing files between the host and the vm, but I have not gotten to this part and I am currently looking for help in documenting those steps.*


## Dependencies

* docker
* docker-compose (optional but highly recommended)


## Configure

Configuration is esily managed using `docker-compose`. You can find an example in [./docker-compose.yml](https://github.com/jakkn/nwn-devbase/blob/master/docker/docker-compose.yml).

Please note that you need the NWN sources installed on your computer to use the image, as the *data* folder has been stripped from the image to reduce the size. So the volume mounts must match with your computer environment to mount the necessary NWN files. At the very least the data folder must be mounted.


## Run

### With docker-compose
```
docker-compose up -d
```
Stop (and remove all containers including volumes) with
```
docker-compose stop
```


### With docker
In the below subsections, change
- `PATH_TO_REPO` with the path to your repository on the host system
- `PATH_TO_NWN` with the path to your NWN install dir

#### Create the database container
```
docker pull mysql:5.7
docker run \
  --name nwn-mysql \
  -v PATH_TO_REPO/docker/database:/docker-entrypoint-initdb.d \
  -e MYSQL_ROOT_PASSWORD=password \
  -d \
  mysql:5.7
```

#### Create the nwserver container
To function properly, the container needs access to the
- host directory containing the essential NWN *.bif* files
- host directory containing the module
- database container

```
docker run -it \
  -v PATH_TO_NWN/data:/opt/nwnserver/data \
  -v PATH_TO_REPO/packed:/opt/nwnserver/modules \
  --link nwn-mysql:mysql \
  -p 5121:5121/tcp \
  -p 5121:5121/udp \
  --name nwn-devbase-test \
  nwn-devbase:latest
```

`-v` mounts a host directory as a volume in the container. `--link nwn-mysql:mysql` creates a link between the mysql container and the nwn-devbase-test container. Note: the name following the colon - *mysql* in this case - is the name of the server, and must correspond with the database server specified in the nwnx2.ini, but this should work out of the box unless it has been changed in the Dockerfile. `-p` specifies which container ports to expose to the host system. Docker will not expose UDP by default and must be specified to enable nwserver connections.

The procedure is similar if you need haks, overrides, or other custom files. The below example adds folders *hak*, *tlk*, and *erf*.
```
docker run -it \
  -v PATH_TO_NWN/data:/opt/nwnserver/data \
  -v PATH_TO_NWN/hak:/opt/nwnserver/hak \
  -v PATH_TO_NWN/tlk:/opt/nwnserver/tlk \
  -v PATH_TO_NWN/erf:/opt/nwnserver/erf \
  -v PATH_TO_REPO/packed:/opt/nwnserver/modules \
  --link nwn-mysql:mysql \
  -p 5121:5121/tcp \
  -p 5121:5121/udp \
  --name nwn-devbase-test \
  nwn-devbase:latest
```

#### Restarting the container
From now on you should only need the following two commands to start and stop the server.
```
docker restart testserver
docker stop testserver
```

#### View the logs
Either mount the logs folder to the host, or attach to the running container in a new shell with `docker exec -it nwn-devbase-test /bin/bash`

#### Attach to the running server
```
docker attach nwn-devbase-test
```
Detach safely with `ctrl+p ctrl+q`


## Play

Direct connect to `localhost:5121` from your NWN game client.


## Windows

*Note to non-Linux users: At the time of writing there are no Windows images for nwserver, and I have no plans to make any because nwnx2-win32 is discontinued. Consequently, running nwserver in a docker container is restricted to Linux (OSX should work but is currently untested). This can be accomplished on Windows by the use of a virtual machine and sharing files between the host and the vm, but I have not gotten to this part and I am currently looking for help in documenting those steps.*


## OSX
I don't run OSX and neither does anyone else at BoP. If anyone wants to fill this guide please go ahead.
