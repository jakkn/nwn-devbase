# Using Docker

When you start a Docker image with the `docker run IMAGE` command, Docker creates what is called a container. Containers are instances of an image and are considered disposable. Everything you do in a container stays in the container. Containers should be used over again to avoid unnecessary container buildup.

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


## Linux

In the below subsections, change `PATH_TO_REPO` with the path to your repository on the host system.

### Create the database container
```
docker pull mysql:5.7
docker run \
  --name nwn-mysql \
  -v PATH_TO_REPO/docker/database:/docker-entrypoint-initdb.d \
  -e MYSQL_ROOT_PASSWORD=password \
  -d \
  mysql:5.7
```

### Create the nwserver container

To function properly, the container needs access to the
- host directory containing the module
- database container

```
docker run -it \
  -v PATH_TO_REPO/packed:/opt/nwnserver/modules \
  --link nwn-mysql:mysql \
  -p 5121:5121/tcp \
  -p 5121:5121/udp \
  --name boptest \
  bop-testserver:latest
```

`-v` mounts a host directory as a volume in the container. `--link nwn-mysql:mysql` creates a link between the mysql container and the boptest container. Note: the name following the colon - *mysql* in this case - is the name of the server, and must correspond with the database server specified in the nwnx2.ini, but this should work out of the box unless it has been changed in the Dockerfile. `-p` specifies which container ports to expose to the host system. Docker will not expose UDP by default and must be specified to enable nwserver connections.

The procedure is similar if you need haks, overrides, or other custom files. The below example adds folders *hak*, *tlk*, and *erf*, assumed located on host system at */opt/nwn/*
```
docker run -it \
  -v PATH_TO_REPO/packed:/opt/nwnserver/modules \
  -v /opt/nwn/hak:/opt/nwnserver/hak \
  -v /opt/nwn/tlk:/opt/nwnserver/tlk \
  -v /opt/nwn/erf:/opt/nwnserver/erf \
  --link nwn-mysql:mysql \
  -p 5121:5121/tcp \
  -p 5121:5121/udp \
  --name boptest \
  bop-testserver:latest
```

### Restarting the container
`docker run` will by default run the last CMD command defined in the Dockerfile. To exit the container simply type `exit`.

From now on you should only need the following two commands to start and stop the server.
```
docker restart testserver
docker stop testserver
```
To view log output you may copy logs.0 from the container by running `docker cp boptest:/opt/nwnserver/logs.0 .`

## Windows
This is a little tricky on Windows, as Docker runs in a VM and the directory must be shared with the VM. Instructions to come, but for now see [docker userguide](http://docs.docker.com/engine/userguide/dockervolumes/).

## OSX
This is a little tricky on OSX, as Docker runs in a VM and the directory must be shared with the VM. Instructions to come, but for now see [docker userguide](http://docs.docker.com/engine/userguide/dockervolumes/).

I don't run OSX and neither does anyone else at BOP. If anyone wants to fill out this please go ahead.


## Connect to the server
Direct connect to `localhost:5121` from your NWN game client.
