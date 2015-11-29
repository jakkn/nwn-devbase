@ECHO OFF


:: Try to setup nwntools if necessary
IF NOT EXIST ..\nwntools\ModUnpacker.cmd (
	CD ..\nwntools
	CALL setup.cmd
	CD ..\scripts
)

:: Exit early if there is no ModUnpacker
IF NOT EXIST ..\nwntools\ModUnpacker.cmd (
	ECHO Cannot find ModUnpacker utility. Did you run \nwntools\setup.cmd?
	Exit /b
)

:: Exit early if there is no module to unpack
IF NOT EXIST ..\packed\test_server.mod (
	ECHO Cannot find module to unpack. Check ..\packed\ directory.
	Exit /b
)

ECHO Setting nwntools environment variables...
CD ..\nwntools
CALL setpath.cmd

IF EXIST ..\tmp (
	ECHO Cleaning temporary storage...
	DEL ..\tmp /Q
) ELSE ( MD ..\tmp )

ECHO Extracting module to temporary storage...
CALL ModUnpacker.cmd ..\packed\testserver.mod ..\tmp

IF EXIST ..\unpacked (
	ECHO Cleaning old sourcefiles...
	RD /S /Q ..\unpacked
)
MD ..\unpacked

ECHO Moving sources into unpacked\ ...
CD ..\tmp
FOR %%i IN (*) DO (
	IF EXIST %%i (
		SETLOCAL enabledelayedexpansion
		SET ext=%%~xi
		SET ext=!ext:~1!
		MD ..\unpacked\!ext!
		MOVE *!ext! ..\unpacked\!ext! >nul
		ENDLOCAL
	)
)

ECHO Deleting temporary storage...
RD /S /Q ..\tmp

CD ..\scripts
ECHO Done.
