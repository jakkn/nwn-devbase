# nwn-devbase

nwn-devbase is a cli tool for transforming _.mod_ archives to YAML and back, intended to enable Neverwinter Nights (NWN) module developers to version control their module development. The tool supports both vanilla NWN and NWN:EE

In addition, the texts here are meant to function as a reference for users unfamiliar with git and Docker. [INTRODUCTION](https://github.com/jakkn/nwn-devbase/blob/master/INTRODUCTION.md) introduces the problem areas git and Docker solve, and attempts to explain the development workflow.

The basis for this work is what I have already done on an existing server; [Bastion of Peace](https://www.facebook.com/nwnbastionofpeace/).

## Why do I need this?

You don't, but it might make version controlling your module development easier and more productive for you. It's not optimal to version control a mod archive directly, nor the gffs it unpacks to, because git considers these file formats as binary. You want to version control text, and this conversion is not straight forward.

## Quickstart reference

Initialize new projects by running

```bash
mkdir my-project && cd my-project
git init
nwn-build init
cp path-to-my-module.mod server/modules/
nwn-build extract
git add -A && git commit -m "Initial commit"
```

`nwn-build init` does the following:

1.  `.nwnproject` is created
2.  `.nwnproject/.gitignore` is created to exclude the `cache` dir, unless it's already there
3.  Prompts to specify the module file name
4.  `.nwnproject/config.rb.in` is created with a configuration that specifies the module filename, unless it's already there
5.  Prompts to create the expected directory for the module at `./server/modules/`
6.  If yes, `.gitignore` is created to exclude the `server` dir, unless it's already there

These files are important. Start tracking them with `git add -A && git commit "Initial commit"`

See `nwn-build -h` for further usage instructions.

## Common dependencies

_Note to windows users: chocolatey is a package manager for Windows that empowers you to install and upgrade software from the command line. For those not using chocolatey the direct download links follow after the choco command._

Everyone will need git

* Arch: `pacman -S git`
* Ubuntu: `apt install git`
* Windows: `choco install git` [git-scm.com](https://git-scm.com/download/win)

## Install and run

You can run nwn-devbase in the following ways:

1.  Natively
2.  or in a docker container

To run natively you have to install Ruby, nim, neverwinter_utils.nim, and an nss compiler. To run with docker you only need docker installed.

### Docker

nwn-devbase has been containerized with the intention of easing up on the dependencies and configurations required to run natively, by only requiring Docker. The image `jakkn/nwn-devbase` should be used to spin up short lived containers that run a single command and dies quietly when they're done.

Use the following command to run devbase in a container

```
docker run --rm -it --user $UID:$UID -v "$(pwd):/home/devbase/build" jakkn/nwn-devbase
```

It is recommended to alias this command to something like `nwn-build`.
Linux: append to ~/.bashrc

```bash
alias nwn-build="docker run --rm -it --user $UID:$UID -v \"$(pwd):/home/devbase/build\" jakkn/nwn-devbase"
```

Windows: TODO - Figure out how to store PS functions. Help wanted!

```PowerShell
function nwn-build {docker run --rm -it -v \"$(pwd):/home/devbase/build\" jakkn/nwn-devbase}
```

Limitations:

* The command must be run in the project root, because docker cannot navigate to the parent of the mounted volume in the host directory tree
* Linux host only: The container runs with UID 1000 by default if `--user` is not specified

Install Docker:

* Arch: `pacman -S docker`
* Ubuntu: See [https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/)
* Windows: Depends on Hyper-V support (Windows Pro and above), please refer to [https://forums.docker.com/t/linux-container-on-windows-docker-host/25884/2](https://forums.docker.com/t/linux-container-on-windows-docker-host/25884/2) for details.
  * No Hyper-V: `choco install virtualbox docker-toolbox`
  * With Hyper-V: `choco install docker-for-windows`

Update the image by running `docker pull jakkn/nwn-devbase`

### Natively

You will need

* Ruby, to run the build script and nwn-lib to convert gff to yml

  * Arch: `pacman -S ruby`
  * Ubuntu: `apt install ruby`
  * Windows: `choco install ruby` [rubyinstaller.org](https://rubyinstaller.org/downloads/)

* nwnsc, the nwscript compiler

  * All platforms: [https://neverwintervault.org/project/nwn1/other/tool/nwnsc-nwn-enhanced-edition-script-compiler](https://neverwintervault.org/project/nwn1/other/tool/nwnsc-nwn-enhanced-edition-script-compiler)

* nim, to use neverwinter_utils.nim

  * Arch: `pacman -S nim`
  * Ubuntu: [choosenim](https://github.com/dom96/choosenim)
  * Windows: [choosenim](https://github.com/dom96/choosenim)

* neverwinter_utils.nim for module packing and extracting

  * All platforms: [https://github.com/niv/neverwinter_utils.nim](https://github.com/niv/neverwinter_utils.nim)

Install nwn-devbase

```bash
git clone https://github.com/jakkn/nwn-devbase.git
cd nwn-devbase
gem install bundler
bundle install
```

If there are errors it is most likely due to improper Ruby configurations or missing PATH entries. See [troubleshooting](https://github.com/jakkn/nwn-devbase#troubleshooting).

## Symlinks

Symbolic links are used to make files appear in multiple directories. This is useful for making build.rb available on PATH, and to reveal _.mod_ files to the aurora toolset which is necessary because devbase build the module to `PATH_TO_REPO/server/modules/module.mod` while the toolset looks for the file in _NWN_USERDIR/modules/_.

### Linux

You may run `ruby build.rb install` to automatically symlink `build.rb` to `$HOME/bin/nwn-build`. If you do this, make sure `$HOME/bin` is on your PATH, see [Paths](https://github.com/jakkn/nwn-devbase#paths) for details. Alternatively run `ln -s "$(pwd)/build.rb" "/usr/local/bin/nwn-build"` or modify the destination to your preference.

Make a module accessible to the toolset by running
`ln -s "PATH_TO_REPO"/server/modules/my-module.mod "NWN_USERDIR"/modules/`
Replace _NWN_USERDIR_ with the path to where your local NWN client reads modules from, and _PATH_TO_REPO_ with the path to the repository of a given project.

### Windows

Run all shell commands in PowerShell. Alternatively use [Link Shell Extension](http://schinagl.priv.at/nt/hardlinkshellext/linkshellextension.html) to create symbolic links instead of using the shell.

Use the right click menu from Link Shell Extension, or run `cmd /c MKLINK "$env:USERPROFILE\bin\nwn-build.rb" "$(pwd)\build.rb"`, and make sure `$HOME/bin` is on your PATH, see [Paths](https://github.com/jakkn/nwn-devbase#paths) for details.

Make a module accessible to the toolset by running
`cmd /c MKLINK "NWN_USERDIR\modules\my-module.mod" "PATH_TO_REPO\server\modules\my-module.mod"`
Replace _NWN_USERDIR_ with the path to where your local NWN client reads modules from (mine is ), and _PATH_TO_REPO_ with the path to the repository of a given project.

## Paths

Information on what environment variables are can be found by looking at the [wikipedia article](https://en.wikipedia.org/wiki/Environment_variable).
Instructions on how to set one can be found using [google](https://www.google.no/search?q=windows+set+system+environment+variable+gui&oq=windows+set+system+environment+variable+gui&aqs=chrome..69i57j69i60.1593j0j9&sourceid=chrome&ie=UTF-8).

For nss compilation to work, it may be necessary to set some PATHs if the defaults do not match with your system environment. Either specify the paths at run time with

```bash
NWN_USERDIR="$HOME/Beamdog Library/00829" NSS_COMPILER="$HOME/bin/nwnsc" nwn-build compile
```

or set them permanently in system environment variables. Placing the compiler in a folder on PATH, like `$HOME/bin` should also work.

#### NSS compiler

`build.rb` looks for the _NSS_COMPILER_ environment variable, and defaults to `nwnsc` if that does not exist. Either add the compiler to your PATH, or create the NSS_COMPILER environment variable that points to the nss compiler of your choice.

#### NWN install dir

The compiler run arguments specify game resources located in _NWN_USERDIR_ environment variable. This is needed to locate `nwscript.nss` and base game includes.

## Use

```
ruby ./build.rb -h
```

To version control your changes to the sources use the git commands `git pull`, `git add`, `git commit`, `git push` accordingly.

#### Hints

##### Scripting in other editors

Some might find other editors to be faster, easier to navigate, and to provide better syntax highlighting than the Aurora toolset.

###### Visual Studio Code

VSCode is an excellent choice for scripting outside of the toolset. The editor will prompt you to add the nwscript extension when you open a .nss file.

###### Sublime Text

_TODO: OUTDATED INSTRUCTIONS_
Setting up Sublime Text for scripting requires a few steps to set up the custom NWN script compiler (NWNScriptCompiler).

* Install [Sublime Text 3](http://www.sublimetext.com/3)
* Install [Package Control](https://packagecontrol.io/installation)
* Install [STNeverwinterScript](https://github.com/CromFr/STNeverwinterScript) plugin
* Open the Sublime project described by the file nwn-devbase.sublime-project located in the root directory of this repository
* Tools->Build System->NWN compile
* Hit ctrl+b to compile open nss files or ctrl+shift+b for all the other build options

##### Windows PowerShell

Windows users may find this blog post titled [make powershell and git suck less on windows](http://learnaholic.me/2012/10/12/make-powershell-and-git-suck-less-on-windows/) useful.

## Troubleshooting

"Too many files open": nwn-lib opens all files for reading at the same time when packing the module. This can lead to an error stating too many files are open.
Fix:

* _Linux_ `ulimit -n 4096` (or any other number higher than the number of files in the module)
* _Windows_ the Java library modpacker is used instead. If modpacker cannot be found build.rb will print out instructions.

I have installed Ruby but it does not work: This is most likely due the Ruby executable missing from your PATH environment variable. If this is new to you and you're on Windows, [please ask google first](https://www.google.com/search?q=windows+path&oq=windows+path&aqs=chrome.0.0l6.1280j0j1&sourceid=chrome&ie=UTF-8#q=windows+10+change+path). Linux users should not have this issue.

## build.rb illustration

An illustration of how the build script operates is available at https://drive.google.com/file/d/156hELaw_3fwGeCWexYFmJDJiBrJu23-x/view?usp=sharing

## Feedback

Feedback is greatly appreciated. If you have any thoughts, suggestions or ideas about how to improve this project, please feel free to raise issues, create pull requests, or look me up on email or on discord.
