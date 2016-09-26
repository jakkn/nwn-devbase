@ECHO OFF

:: Exit early if no modpacker directory
IF NOT EXIST modpacker (
	ECHO Please download and extract modpacker.zip to directory bin/modpacker https://sourceforge.net/projects/nwntools/files/ModPacker/Version%201.0.0/
	TIMEOUT /t -1
	EXIT /b
)

CD modpacker
:: Try to setup nwntools if necessary
IF NOT EXIST modpacker\ModPacker.cmd (
	CALL setup.cmd
)

:: Exit early if there is no ModPacker executable
IF NOT EXIST ModPacker.cmd (
	ECHO Cannot find ModPacker utility. Did you run setup.cmd?
	TIMEOUT /t -1
	Exit /b
)

ECHO Setting nwntools environment variables...
CALL setpath.cmd

CALL ModPacker.cmd ..\..\cache\tmp ..\..\module\testserver.mod

CD ..\
ECHO Done.
