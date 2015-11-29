@ECHO OFF


:: Try to setup nwntools if necessary
IF NOT EXIST ..\nwntools\ModPacker.cmd (
	CD ..\nwntools
	CALL setup.cmd
	CD ..\scripts
)

:: Exit early if there is no ModPacker
IF NOT EXIST ..\nwntools\ModPacker.cmd (
	ECHO Cannot find ModPacker utility. Did you run \nwntools\setup.cmd?
	Exit /b
)

:: Exit early if there are no sources to pack
IF NOT EXIST ..\unpacked\ (
	ECHO Cannot find module sources to pack. Check unpacked\ directory.
	Exit /b
)

ECHO Setting nwntools environment variables...
CD ..\nwntools
CALL setpath.cmd

IF EXIST ..\tmp (
	ECHO Cleaning temporary storage...
	DEL ..\tmp /Q
) ELSE ( MD ..\tmp )

ECHO Copying resources to temporary storage...
CD ..\unpacked
FOR /D %%d IN (*) DO (XCOPY %%d ..\tmp /Q)

IF NOT EXIST ..\packed\ (MD ..\packed)

CD ..\nwntools
CALL ModPacker.cmd ..\tmp ..\packed\testserver.mod

ECHO Deleting temporary storage...
RMDIR /S /Q ..\tmp

CD ..\scripts
ECHO Done.
