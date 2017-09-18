# Setup

**Intended audience: server admins**

This document covers initializing the repository and managing the Docker image.

The following topics are covered:

- [Applying version control](#git)
- [Configuring the local testing environment](#docker)

Either can be used independently, though I recommend both.


## Dependencies

* git


## git

The skeleton is made up by the ruby scripts and the libraries they use. Either copy-paste the ruby files over to your project, or clone this repository and change the origin. Cloning has the added benefit of being able merge any future changes to this boilerplate project with your project. To clone, run
```
git clone --depth=1 -o boilerplate https://github.com/jakkn/nwn-devbase.git nwn-my-project
cd nwn-my-project
git remote add origin ssh://git@bitbucket.org/user/nwn-my-project.git
git branch --set-upstream-to origin/master
```
Please note:

- If you clone it is adviced to set the new remote origin to a private repository (bitbucket.org/user/nwn-my-project.git is just an example), as you may not want to expose module content to anyone outside the team. I recommend using BitBucket as GitHub charges money per private repository, while Bitbucket is free for up to 5 collaborators. See [how to make private](https://confluence.atlassian.com/bitbucket/make-a-repo-private-or-public-221449724.html)
- Setting the upstream may fail if the remote does not exist
- To initialize the repository:
    1. Place your *.mod* file in the designated directory *nwn-my-project/module/*
    2. Run the extract command (see [README](https://github.com/jakkn/nwn-devbase/blob/master/README.md))
    3. Add, commit, push


## Docker

There are two images that you can use; [jakkn/nwnserver](https://hub.docker.com/r/jakkn/nwnserver/) loads a standard NWN server and [jakkn/nwnx2server](https://hub.docker.com/r/jakkn/nwnx2server/) adds NWNX to the the former.  These images are written with the intention of being as generic as possible to facilitate reuse. As such, you don't have to build your own image because configurations like nwserver switches and the enabling of NWNX plugins are given as arguments to `docker run`.

Still, some settings do not have runtime switches so there is a `Dockerfile` present in the `docker` folder for your convenience, and compose is set to use it by default. You can expand on the sample `sed` commands to make further config changes that match your preferences.

### Database

Compose takes care of linking the nwserver and db services, so **nwnx_odbc** finds and connects to the db automatically.

A default schema containing an empty pwdata table is loaded to the MySQL instance. The table dump can be found in *docker/mysql-db/init_pwdata.sql*. If you have any custom tables this is where they need to go.

If you wish to use SQLite or PostgreSQL instead simply change the plugin configuration in `docker-compose.yml` from `--mysql` to `--postgre` or `--sqlite3` and change the db service accordingly. I assume people who do this know what they are doing and will not document further details.

Loading module, haks and other files is part of running the docker image and is covered in the [DOCKERGUIDE](https://github.com/jakkn/nwn-devbase/blob/master/DOCKERGUIDE.md).
