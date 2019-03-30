# Windows

## Install Natively

### [Install Chocolatey](https://chocolatey.org/install#installing-chocolatey) (optional)

### [Install git](https://git-scm.com/)
[Download](https://git-scm.com/download/)
or
```bat
choco install git
```

### [Install Ruby](https://www.ruby-lang.org/)
[Download](https://rubyinstaller.org/downloads/)
or
```bat
choco install ruby
```

### [Install nim](https://nim-lang.org/)
1. [Download](https://nim-lang.org/install_windows.html)
2. Add nim to PATH:
```%USERPROFILE%\.nimble\bin```
or 
where your nim is installed (you can check it when installs).

### [Install neverwinter_utils.nim](https://github.com/niv/neverwinter.nim)
```bat
nimble install neverwinter
```

### [Install nwnsc](https://gitlab.com/glorwinger/nwnsc)
1. [Download](https://neverwintervault.org/project/nwnee/other/tool/nwnsc-nwn-enhanced-edition-script-compiler)
2. Extract in some folder under your watch like ```%USERPROFILE%\bin```
3. Add nwnsc.exe folder to PATH (optional)

### [Install nwn-devbase](https://github.com/jakkn/nwn-devbase)
```bat
git clone https://github.com/jakkn/nwn-devbase.git
cd nwn-devbase
gem install bundler
bundle install
```

## First usage

### Without PATH
```bat
mkdir my-project && cd my-project
git init
ruby path-to-nwn-devbase/build.rb init
cp path-to-my-module.mod server/modules/
ruby path-to-nwn-devbase/build.rb extract
git add -A && git commit -m "Initial commit"
```

### With PATH
Create if it does not exist, and add ```%USERPROFILE%\bin``` to PATH.
Being in nwn-devbase folder, execute in PowerShell:
```posh
cmd /c MKLINK "$env:USERPROFILE\bin\nwn-build.rb" "$(pwd)\build.rb"
```
And then:
```bat
mkdir my-project && cd my-project
git init
nwn-build init
cp path-to-my-module.mod server/modules/
nwn-build extract
git add -A && git commit -m "Initial commit"
```

## Pack and compile
For nss compilation to work, it may be necessary to set some PATHs if the defaults do not match with your system environment. Either specify the paths at run time with

```bat
NWN_USERDIR="%programfiles(x86)%/Steam/steamapps/common/Neverwinter Nights" NSS_COMPILER="%USERPROFILE%/bin/nwnsc" nwn-build compile
```
or set them permanently in system environment variables. Placing the compiler in a folder on PATH, like `%USERPROFILE%/bin` should also work.

#### NSS compiler
`build.rb` looks for the _NSS_COMPILER_ environment variable, and defaults to `nwnsc` if that does not exist. Either add the compiler to your PATH, or create the NSS_COMPILER environment variable that points to the nss compiler of your choice.

#### NWN install dir
The compiler run arguments specify game resources located in _NWN_USERDIR_ environment variable. This is needed to locate `nwscript.nss` and base game includes.

#### PACK
Close Aurora Toolset project before.
```bat
nwn-build pack
```

## Toolset
To locate your .mod packed file in some other folder that is required by the Aurora toolset you can create a symbolic link with the following command in Power Shell:
```posh
cmd /c MKLINK "NWN_USERDIR\modules\my-module.mod" "PATH_TO_REPO\server\modules\my-module.mod"
```
Replace NWN_USERDIR with the path to where your local NWN client reads modules from (%USERPROFILE%\Documents\Neverwinter Nights\modules), and PATH_TO_REPO with the path to the repository of a given project.