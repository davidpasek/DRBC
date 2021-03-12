@set OLDDIR=%CD%

REM START STANDBY SERVERS IN ISOLATED ENVIRONMENT
cd C:\DRBC\Scripts\vipt
drbc.pl --action start_standby_dc_without_vc
drbc.pl --action start_standby_servers

@chdir /d %OLDDIR%
