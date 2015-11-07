# nwn-devbase
This repository is meant to function as a base setup for anyone who wants to version control their module development for the game Neverwinter Nights, using git. It also contains instructions for setting up a local testing environment using Docker, which can be easily distributed to the development team.


### How to use
There are two parts:
1. [Applying version control][git]
2. [Setting up the local testing environment][Docker]

#### git
1. Fork repository
2. Change permissions
	- I suggest you make the fork private to not expose module content to anyone but your team. I also recommend using BitBucket as GitHub charges money per private repository. See [how to fork](https://confluence.atlassian.com/bitbucket/forking-a-repository-221449527.html) and [how to make private](https://confluence.atlassian.com/bitbucket/make-a-repo-private-or-public-221449724.html). It may also be an idea to change the repository name to reflect your project.
3. Place your *.mod* archive in the designated directory
4. Run the unpack script

You are now ready to add and commit the module's content to your own repository. That's it. Of course, if you're not familiar with version control you should read up on git and familiarize yourself with what it is, how to use it, and best practices.

#### Docker
The Dockerfile is based on a 32-bit Ubuntu image, and will download and install all files necessary to run vanilla NWN modules. The image is hosted at [jakkn/nwnx2server](https://hub.docker.com/r/jakkn/nwnx2server/), and will by default load the "Contest Of Champions 0492" module.

##### Docker basics
When Docker runs an *image* it starts what is called a *container*. The container is a running instance of an image, and once created should be used over again to avoid unnecessary buildup of containers.

**Useful common docker commands**

List all images
```
docker images
```
Remove image
```
docker rmi image-id
```
List all containers
```
docker ps -a
```
Remove container
```
docker rm container-name
```

##### Running Vanilla NWN
Follow these steps shows how to run a container with a different module than the default one:
1. Modify the Dockerfile to reflect the name of your module. The below example specifies the module "Goblin Castle"
	```
	RUN sed -i \
	-e's/Contest Of Champions 0492/Goblin Castle/g' \
    nwnstartup.sh
	```
2. At this point, see [nwnx plugins][Running with nwnx plugins] if you want to add nwnx plugins
3. Build the image (the -t argument specifies the image name and may be omitted/changed)
	```
	docker build -t nwnserver .
	```
4. Mount the directory containing the module on your host computer in the container
	[Mount a host directory as a data volume](http://docs.docker.com/engine/userguide/dockervolumes/). This is a little tricky on OSX and Windows, as Docker runs in a VM and the directory must shared with the VM. See link for instructions.
	
	Linux example below. If you want to add haks or overrides, see [custom hak, override, tlk, erf][Running with custom hak, override, tlk, erf] instead
	```
	docker run -it \
	    -v /home/user/nwn-devbase/packed:/opt/nwnserver/modules \
	    -p 5121:5121/tcp \
	    -p 5121:5121/udp \
	    --name testserver \
	    nwnserver
	```

###### Running with nwnx plugins
The below example shows a complete Dockerfile that symlinks the odbc and profiler plugins to /opt/nwnserver
	```
	FROM jakkn/nwnx2server

	# Copy compiled sources to nwnserver
	WORKDIR /usr/local/src/nwnx2-linux/build/compiled
	RUN ln -s $(pwd)/nwnx_odmbc_mysql.so /opt/nwnserver/nwnx_odbc.so \
	    && ln -s $(pwd)/nwnx_profiler.so /opt/nwnserver/nwnx_odbc.so
	
	# Change YourModuleHere with your module name
	WORKDIR /opt/nwnserver
	RUN sed -i \
	    -e's/Contest Of Champions 0492/YourModuleHere/g' \
	    nwnstartup.sh
	
	# Default entrypoint
	CMD ["./nwnstartup.sh"]
	
	```

###### Running with custom hak, override, tlk, erf
The below example mounts folders hak, tlk, and erf to /opt/nwnserver/
	```
	docker run -it \
	    -v /home/user/nwn-devbase/packed:/opt/nwnserver/modules \
	    -v /opt/nwn/hak:/opt/nwnserver/hak \
	    -v /opt/nwn/tlk:/opt/nwnserver/tlk \
	    -v /opt/nwn/erf:/opt/nwnserver/erf \
	    -p 5121:5121/tcp \
	    -p 5121:5121/udp \
	    --name testserver \
	    nwnserver
	```

##### Connecting to the server
Direct connect to *localhost:5121*

### Background
Neverwinter Nights is an RPG developed by BioWare and released in 2001. BioWare designed NWN as a game where players may create their own game worlds, and share their work with the community. Module development is done through the use of the Aurora Toolset that BioWare released with NWN. BioWare also released server software for launching and hosting modules online so that players may connect to and play the modules created and hosted by module developers.

NWN was discontinued 7 years after release, and the final patch is version 1.69, released 9 July 2008. Even though the game was discontinued by the developer, the community is still big, and due to the game's easily hackable design new game content is continually released.


### What's the point of this repository
Aurora stores all module content in file archives with the .mod extension. git does not handle .mod archives well, and so for git to be of any use the .mod archive must first be unpacked. The process of unpacking and repacking module content may be cumbersome to some, and so I've created this repository in an attempt to share the work I've done with anyone who may find it useful, and to reuse for my own use should I ever need it. As such, the basis for this work and some of the documentation is the work I've already done on an existing server - Bastion of Peace.


### Feedback
Feedback is greatly appreciated. If you have any thoughts, suggestions or ideas about how to improve the content of this project, please feel free to contact me, or even better; improve it and make a pull request.
