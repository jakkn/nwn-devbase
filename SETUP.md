# Setup
This document is intended for those in charge of setting up the repository and managing the Docker image.

The document covers the following:

- [Applying version control](#git)
- [Configuring the local testing environment](#docker)

Either can be used independently, but I recommend both.

---

## git
1. Fork repository
2. Change permissions
	- I suggest you make the fork private if you don't want to expose module content to anyone but your team. I also recommend using BitBucket or GitLab, as GitHub charges money per private repository. See [how to fork](https://confluence.atlassian.com/bitbucket/forking-a-repository-221449527.html) and [how to make private](https://confluence.atlassian.com/bitbucket/make-a-repo-private-or-public-221449724.html).
3. Rename the repository to reflect your project, e.g. at BoP our repo is named nwn-bop
4. Place your *.mod* archive in the designated directory
5. Change the module name in the pack scripts
6. Run the unpack script
7. Add, commit, push.

---

## Docker
The Dockerfile is based on [jakkn/nwnx2server](https://github.com/jakkn/nwnx2server/blob/master/Dockerfile) which again is based on a 32-bit Ubuntu image, and contains all files necessary to run vanilla NWN modules. The image will by default start a vanilla NWN server and load the "Contest Of Champions 0492" module. It has been made with the intention of being as generic as possible to facilitate reuse.

The guide assumes use of the nwnx_odbc plugin and will configure accordingly. This section covers two topics: the server Dockerfile, and database usage.

### Customizing the server Dockerfile
To create an image that will automatically load your module you must modify the [Dockerfile](https://github.com/jakkn/nwn-devbase/blob/master/docker/Dockerfile).

Below is an example of what we do at Bastion of Peace.
```
FROM jakkn/nwnx2server

# Symlink compiled sources to nwnserver
WORKDIR /usr/local/src/nwnx2-linux/build/compiled
RUN ln -s $(pwd)/nwnx_odmbc_mysql.so /opt/nwnserver/nwnx_odbc.so \
    && ln -s $(pwd)/nwnx_profiler.so /opt/nwnserver/nwnx_profiler.so

# Specify module name
WORKDIR /opt/nwnserver
RUN sed -i \
    -e's/Contest Of Champions 0492/bop-testserver/g' \
    nwnstartup.sh

# Configure mysql database in nwnx2.ini
WORKDIR /opt/nwnserver
COPY enabledb.pl .
RUN ./enabledb.pl -d mysql
RUN sed -i \
    -e's/^debuglevel=\d/debuglevel=4/g' \
    -e's/^user=username/user=root/g' \
    -e's/^pass=password/pass=password/g' \
    -e's/^db=database/db=testserver/g' \
    nwnx2.ini

# nwnx2 prints to stdout if logdir doesn't exist
RUN mkdir logs.0

# Default entrypoint
CMD ["./nwnstartup.sh"]
```

I used mysql here but you if you want sqlite3 or postgre link one of those instead.

Configuring nwnx2.ini is easiest done using *sed* commands, but database configuration spans several lines and either needs manual editing or a more advanced tool. I have written a pearl script to automate (un)commenting of the database config fields. The script will uncomment the desired database fields and comment out the others. Note that the script does not gracefully handle all kinds of input so please use it as intended, where the -d argument should be either `mysql`, `sqlite3` or `postgre`.

`COPY enabledb.pl .` sees the script because it is placed in the same directory as the Dockerfile. `RUN ./enabledb.pl -d mysql` executes it.

#### Building the Docker image
Build the image with the command
```
docker build -t bop-testserver:latest .
```
where `-t bop-testserver:latest` specifies containername:tag and may be changed/omitted.

#### Distribution

You have two choices:

- Have your team build the image locally by running `docker build -t containername:tag .`
- Upload the image to as server and have your team run `docker pull IMAGE`

[DockerHub](https://hub.docker.com/) provides free image hosting, but keep permissions in mind if you have put anything in the image that you want hidden from public view.


### Database

The [official Docker MySQL image](https://hub.docker.com/_/mysql/) is perfect out of the box, so there is no need for another Dockerfile. What you need to do is provide a dump of the database for your test server. Running the database container and linking it to the nwserver container is covered in the [DOCKERGUIDE](https://github.com/jakkn/nwn-devbase/blob/master/DOCKERGUIDE.md).

A dump of a standard pwdata table can be found in *docker/database/init_pwdata.sql*. If you have any custom tables, this is a good place to put them. Keeping database dumps here is beneficial in terms of initialization and distribution. Again, if this is sensitive data, make sure your module repository is private.

---

You should now have successfully customized the Dockerfile and produced an image with the correct server environment for your module development.

Loading module, haks and other files is part of running the docker image and is covered in the [DOCKERGUIDE](https://github.com/jakkn/nwn-devbase/blob/master/DOCKERGUIDE.md).
