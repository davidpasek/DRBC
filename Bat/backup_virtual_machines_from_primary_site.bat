@ECHO OFF
set OLDDIR=%CD%

REM CHECK IF PRIMARY SERVERS HASN'T SNAPSHOTS
cd C:\DRBC\Scripts\vipt
drbc.pl --action check_primary_servers_if_exist_snapshot
IF %ERRORLEVEL%==0 GOTO CONTINUE
ECHO !!! CANNOT CONTINUE - some snapshot exists on backup servers !!!
GOTO END

:CONTINUE
REM DELETE OLD VRANGER IMAGES
cd C:\DRBC\Scripts\vranger
vranger.pl -m deleteold -d 4

REM ARCHIVE OLD VRANGER IMAGES
move R:*.* R:\Archive

REM BACKUP VRANGER IMAGES
cd C:\DRBC\Scripts\vranger
vranger.pl -m backup

:END
@chdir /d %OLDDIR%
