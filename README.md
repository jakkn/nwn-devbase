# nwn-devbase
This repository is meant to function as boilerplate for anyone who wants to version control their module development for the game Neverwinter Nights (NWN), using git. It contains a skeleton with the necessary tools, and usage documentation including instructions for setting up a local test environment using Docker, which can easily be distributed to the development team.

In addition, the texts here are meant to function as a reference for users unfamiliar with git and Docker, as is the case with some of my team members. [INTRODUCTION](https://github.com/jakkn/nwn-devbase/blob/master/INTRODUCTION.md) introduces the problem areas git and Docker solve, and attempts to explain how the development process is supposed to work. It also presents an overview of how the systems are wired together.


## But seriously, what's the point?
Can't people just version control their sources without this? Of course they can. However, it is not a straight forward process. The Aurora Toolset stores all module content in file archives with the *.mod* extension. git does not handle *.mod* archives, so for git to be of any use the archive must first be extracted. The process of extracting and packing module content may be cumbersome to some, which is why I have created this repository. It is an attempt at sharing the work I have done so that anyone who may want to do the same can do so with minimal effort. The basis for this work is what I have already done on an existing server; [Bastion of Peace](http://bastionofpeace.enjin.com/).


## Intended audience
- **Admin** - Please see [SETUP](https://github.com/jakkn/nwn-devbase/blob/master/SETUP.md). It contains instructions on how to initialize and customize the repository to your server.
- **Developers** - Continue reading. You will find instructions on how to initialize and use these tools below.


## Dependencies

Please make sure the following software is installed before proceeding:

- git, the version control software
  - Arch: `pacman -S git`
  - Ubuntu: `sudo apt-get install git`
  - Windows: https://git-scm.com/download/win

- Ruby, needed by nwn-lib to pack and extract the *.mod* archive
  - Arch: `pacman -S ruby`
  - Ubuntu: `sudo apt-get install ruby`
  - Windows: http://rubyinstaller.org

- (Optional) Docker, for local test environment
  - Arch: `pacman -S docker`
  - Ubuntu: https://get.docker.com
  - Windows: https://docs.docker.com/engine/installation/windows/


## Initialize

### Get the sources

Your module admin should have provided you with a link to your repository (NOT [nwn-devbase](https://github.com/jakkn/nwn-devbase)!). Cloning can be done via a gui client, or by running `git clone <repository-url>` from the command line.

Using a git client like [SourceTree](https://www.sourcetreeapp.com/) or [another](https://git-scm.com/download/gui/linux) is nice if you prefer a gui, but you can also do everything from the command line. Some git basics and best practices are covered and referenced in [INTRODUCTION](https://github.com/jakkn/nwn-devbase/blob/master/INTRODUCTION.md).

### Install ruby gems

Open a console, navigate to the repository, and type
```
gem install bundler
bundle install
```

If there are errors it is most likely due to improper Ruby configurations or missing PATH entries.

### Symlink

To open the packed module with the Aurora Toolset, symlink the *.mod* file to your *nwn/modules* folder. Run the following command (windows may need admin console), where *PATH_TO_NWN* is the install dir of your local NWN installation, and *PATH_TO_REPO* is the path to the repository.

- Linux: `ln -s "PATH_TO_REPO"/module/module.mod "PATH_TO_NWN"/modules/`
- Windows: `MKLINK "PATH_TO_NWN\modules\" "PATH_TO_REPO\module\module.mod"`

Alternatively there is [Link Shell Extension](http://schinagl.priv.at/nt/hardlinkshellext/linkshellextension.html) for Windows users.

## Use

All use should be done through build.rb, because this script will update the cache properly. Run it from the command line by navigating to the repository root folder, and issue one of the commands below (no argument or wrong argument will print help with usage instructions).

|        Function          |           Command         |
| ------------------------ | ------------------------- |
| Pack *src/* into *.mod*  | `ruby ./build.rb pack`    |
| Extract *.mod* to *src/* | `ruby ./build.rb extract` |
| Compile *.nss* to *.ncs* | `ruby ./build.rb compile` |
| Clean *cache* folder     | `ruby ./build.rb clean`   |

Example use:
```
cd /home/user/nwn-my-module
ruby ./build.rb extract
```

To version control changes to the sources use the git commands `git pull`, `git add`, `git commit`, `git push` accordingly.

For Docker usage, please refer to [DOCKERGUIDE](https://github.com/jakkn/nwn-devbase/blob/master/DOCKERGUIDE.md).

#### Hint
Windows users may find this blog post titled [make powershell and git suck less on windows](http://learnaholic.me/2012/10/12/make-powershell-and-git-suck-less-on-windows/) useful.

## Troubleshooting

"Too many files open": nwn-lib opens all files for reading at the same time when packing the module. This can lead to an error stating too many files are open.
Fix:

- *Linux* `ulimit -n 4096` (or any other number higher than the number of files in the module)
- *Windows* the Java library modpacker is used instead. If modpacker cannot be found build.rb will print out instructions.


## Background
Neverwinter Nights is a RPG developed by BioWare, released in 2001. In addition to the NWN game client, BioWare released a tool for creating game content - the Aurora Toolset - along with server hosting software. This enables anyone to create and host their own worlds.

NWN was discontinued 7 years after release, with the final patch v1.69 released July 9th, 2008. Even though the game was discontinued by the developer, the community is still strong and due to the game's hackable nature new community content is continuously released.


## Feedback
Feedback is greatly appreciated. If you have any thoughts, suggestions or ideas about how to improve this project, please feel free to contact me, or even better; make a pull request.
