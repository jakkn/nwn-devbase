# Windows

## Install Natively

### [Install Chocolatey](https://chocolatey.org/install#installing-chocolatey)

### [Install git](https://git-scm.com/)

[Download](https://git-scm.com/download/win)
or
```bash
choco install git
```

### [Install Ruby](https://rubyinstaller.org/downloads/)
```bash
choco install ruby
```

### [Install nim](https://github.com/dom96/choosenim)

Download nim:
- [Self-extracting archive](https://github.com/dom96/choosenim/releases/download/v0.3.2/choosenim-0.3.2_windows_i386.exe)
or 
- [Zip archive](https://github.com/dom96/choosenim/releases/download/v0.3.2/choosenim-0.3.2_windows_i386.zip), extract and run the ```runme.bat```

Add nim to [PATH](https://www.architectryan.com/2018/03/17/add-to-the-path-on-windows-10/):
C:\Users\YOUR_USER\\.nimble\bin
or 
where your nim is installed (you can check it when installs).

### [Install neverwinter_utils.nim](https://github.com/niv/neverwinter.nim)
```bash
nimble install neverwinter
```

### [Install nwnsc](https://neverwintervault.org/project/nwnee/other/tool/nwnsc-nwn-enhanced-edition-script-compiler)
1. [Download](https://neverwintervault.org/sites/all/modules/pubdlcnt/pubdlcnt.php?file=https://neverwintervault.org/sites/neverwintervault.org/files/project/29016/files/nwnsc-windows-1.0.0.zip&nid=29016)
2. Extract in some folder under your watch
3. Add nwnsc.exe folder to [PATH](https://www.architectryan.com/2018/03/17/add-to-the-path-on-windows-10/) (optional)

### [Install nwn-devbase](https://github.com/jakkn/nwn-devbase)
```bash
git clone https://github.com/jakkn/nwn-devbase.git
cd nwn-devbase
gem install bundler
bundle install
```

## First usage

### Without PATH
```bash
mkdir my-project && cd my-project
git init
ruby path-to-nwn-devbase/build.rb init
cp path-to-my-module.mod server/modules/
ruby path-to-nwn-devbase/build.rb extract
git add -A && git commit -m "Initial commit"
```

### With PATH
Create (if not) and add ```C:\Users\YOUR_USER\bin``` to [PATH](https://www.architectryan.com/2018/03/17/add-to-the-path-on-windows-10/).
Being in nwn-devbase folder, execute in PowerShell:
```bash
cmd /c MKLINK "$env:USERPROFILE\bin\nwn-build.rb" "$(pwd)\build.rb"
```
And then:
```bash
mkdir my-project && cd my-project
git init
nwn-build init
cp path-to-my-module.mod server/modules/
nwn-build extract
git add -A && git commit -m "Initial commit"
```

## Pack and compile
For nss compilation to work, it may be necessary to set some PATHs if the defaults do not match with your system environment. Either specify the paths at run time with

```bash
NWN_USERDIR="$HOME/Beamdog Library/00829" NSS_COMPILER="$HOME/bin/nwnsc" nwn-build compile
```
or set them permanently in system environment variables. Placing the compiler in a folder on PATH, like `$HOME/bin` should also work.

#### NSS compiler

`build.rb` looks for the _NSS_COMPILER_ environment variable, and defaults to `nwnsc` if that does not exist. Either add the compiler to your PATH, or create the NSS_COMPILER environment variable that points to the nss compiler of your choice.

You can also edit ```config.rb.in``` located in your project folder inside ```.nwnproject```.
```
NSS_COMPILER ||= "C:/YOUR_USER/bin/nwnsc"
```

#### NWN install dir

The compiler run arguments specify game resources located in _NWN_USERDIR_ environment variable. This is needed to locate `nwscript.nss` and base game includes.

You can also edit ```config.rb.in``` located in your project folder inside ```.nwnproject```.
```
INSTALL_DIR ||= "C:/Program Files (x86)/Steam/steamapps/common/Neverwinter Nights"
```

#### PACK
Close Aurora Toolset project before.
```bash
nwn-build pack
```

## Toolset
If you are interested in locate your .mod packed file in some other folder that is required by the Aurora toolset you can create a symbolic link with the following command in Power Shell:
```bash
cmd /c MKLINK "NWN_USERDIR\modules\my-module.mod" "PATH_TO_REPO\server\modules\my-module.mod"
```
Replace NWN_USERDIR with the path to where your local NWN client reads modules from (C:\Users\YOUR_USER\Documents\Neverwinter Nights\modules), and PATH_TO_REPO with the path to the repository of a given project.

Some conversations may not extract correctly due some characters specific to some regions. To fix it use the appropriate character encoding in ```.nwnproject/config.rb.in```.
e.g.
```
ENCODING = "utf-8"
```