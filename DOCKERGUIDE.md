
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

