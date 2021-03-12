@set OLDDIR=%CD%

REM SHUTDOWN STANDBY SERVERS IN ISOLATED ENVIRONMENT
cd C:\DRBC\Scripts\vipt
drbc.pl --action shutdown_standby_servers --wait_for_powered_off

REM SHUTDOWN DC SERVER IN ISOLATED ENVIRONMENT
cd C:\DRBC\Scripts\vipt
drbc.pl --action shutdown_standby_dc_without_vc

@chdir /d %OLDDIR%
