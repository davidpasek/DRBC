@ECHO OFF
@set OLDDIR=%CD%

REM DISKPART 
cd C:\DRBC\Scripts\Diskpart
diskpart.pl -m check_rw_all_volumes -d DE
diskpart.pl -m check_volumes_letters -d DE
if %ERRORLEVEL% == 0 GOTO STARTWINSERVICES
ECHO CANNOT START WINDOWS SERVICES
GOTO END

:STARTWINSERVICES
ECHO START WINDOWS SERVICES

ECHO START SERVICE ### mssqlserver ###
net stop mssqlserver /y
SET RETRY=10
:WAIT1
net start mssqlserver
ECHO ERRORLEVEL %ERRORLEVEL%
if %ERRORLEVEL% == 0 GOTO NEXT1
SET /A RETRY=%RETRY%-1
ECHO SLEEP FOR 5 SEC.
ping localhost -n 5
ECHO TRY AGAIN %RETRY%
if %RETRY% GTR 0 GOTO WAIT1
ECHO SERVICE ### mssqlserver ### CANNOT BE STARTED
:NEXT1


ECHO START SERVICE ### sqlserveragent ###
net stop sqlserveragent /y
SET RETRY=10
:WAIT2
net start sqlserveragent
ECHO ERRORLEVEL %ERRORLEVEL%
if %ERRORLEVEL% == 0 GOTO NEXT2
SET /A RETRY=%RETRY%-1
ECHO SLEEP FOR 5 SEC.
ping localhost -n 5
ECHO TRY AGAIN %RETRY%
if %RETRY% GTR 0 GOTO WAIT2
ECHO SERVICE ### sqlserveragent ### CANNOT BE STARTED
:NEXT2

:END
@chdir /d %OLDDIR%
