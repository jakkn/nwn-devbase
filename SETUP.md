# Setup
This document is intended for those in charge of setting up the repository and managing the Docker image.

The document covers the following:

- [Applying version control](#git)
- [Setting up the local testing environment](#docker)

Either can be used independently, but I recommend both.

## git
1. Fork repository
2. Change permissions
	- I suggest you make the fork private if you don't want to expose module content to anyone but your team. I also recommend using BitBucket, as GitHub charges money per private repository. See [how to fork](https://confluence.atlassian.com/bitbucket/forking-a-repository-221449527.html) and [how to make private](https://confluence.atlassian.com/bitbucket/make-a-repo-private-or-public-221449724.html).
3. Rename the repository to reflect your project, e.g. at BoP our repo is named nwn-bop
4. Place your *.mod* archive in the designated directory
5. Change the module name in the pack scripts
6. Run the unpack script
7. Add, commit, push.


## Docker
The Dockerfile is based on a 32-bit Ubuntu image which contains all files necessary to run vanilla NWN modules. The [image](https://hub.docker.com/r/jakkn/nwnx2server/) is created by [this Dockerfile](https://github.com/jakkn/nwnx2server/blob/master/Dockerfile) and will by default start a vanilla NWN server and load the "Contest Of Champions 0492" module. The image has been made with the intention of being as generic as possible to facilitate reuse.

### Customizing the Dockerfile
To create an image that will automatically load your module, *docker/Dockerfile* must be modified.

- Specify your module
- Add any nwnx plugins you use

IMPORTANT! Do not add the module repository in the Dockerfile, as this will be mounted when you run the image (covered in [README](https://github.com/jakkn/nwn-devbase/blob/master/README.md)).

The below Dockerfile specifies the module "BastionOfPeace" and symlinks the odbc and profiler plugins to the server executable directory.
```
FROM jakkn/nwnx2server

# Copy compiled sources to nwnserver
WORKDIR /usr/local/src/nwnx2-linux/build/compiled
RUN ln -s $(pwd)/nwnx_odmbc_mysql.so /opt/nwnserver/nwnx_odbc.so \
    && ln -s $(pwd)/nwnx_profiler.so /opt/nwnserver/nwnx_odbc.so
	
# Change YourModuleHere with your module name
WORKDIR /opt/nwnserver
RUN sed -i \
    -e's/Contest Of Champions 0492/BastionOfPeace/g' \
    nwnstartup.sh
	
# Default entrypoint
CMD ["./nwnstartup.sh"]
```

- If you added nwnx_odbc like in the example above, a database must be added and nwnx2.ini must be configured to use it
	----TODO----

- Build the image. `-t bop-testserver:latest` specifies the image name and may be changed/omitted
```
docker build -t bop-testserver:latest .
```

- (OPTIONAL) Upload the image to a server to make it downloadable with `docker pull IMAGE`. This provides easy access to the image for your team. DockerHub is the easiest alternative, but keep permissions in mind if you have put anything in the image that you want hidden from public view.

You should now have successfully customized the Dockerfile and produced an image with the correct server environment for your module development.

Loading module, haks and other files is part of running the docker image and is covered in the [README](https://github.com/jakkn/nwn-devbase/blob/master/README.md).
