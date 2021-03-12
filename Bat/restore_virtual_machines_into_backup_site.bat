@ECHO OFF
@set OLDDIR=%CD%

REM CHECK IF ALL BACKUPS FOR RESTORE ARE READY
cd C:\DRBC\Scripts\vranger
vranger.pl -m check_today_backups_for_restore
IF %ERRORLEVEL%==0 GOTO RESTORE
GOTO END

:RESTORE
REM SHUTDOWN STANDBY SERVERS & DELETE FROM DISK
cd C:\DRBC\Scripts\vipt
drbc.pl --action shutdown_standby_servers --remove_rdm --deletefromdisk
drbc.pl --action shutdown_standby_dc_without_vc --deletefromdisk

REM RESTORE VRANGER IMAGES
cd C:\DRBC\Scripts\vranger
vranger.pl -m restore

REM SHUTDOWN STANDBY SERVERS & REMOVE THEIR RDM DISKS
cd C:\DRBC\Scripts\vipt
drbc.pl --action shutdown_standby_servers --remove_rdm

REM SHUTDOWN STANDBY SERVERS & ADD REPLICATED RDM DISKS
cd C:\DRBC\Scripts\vipt
drbc.pl --action shutdown_standby_servers --add_rdm

REM RELOCATE STANDBY SERVERS INTO RESOURCEPOOL STANDBY
cd C:\DRBC\Scripts\vipt
drbc.pl --action relocate_standby_dc_into_standby_network_without_vc
drbc.pl --action relocate_standby_servers_into_standby_pool

:END
@chdir /d %OLDDIR%
