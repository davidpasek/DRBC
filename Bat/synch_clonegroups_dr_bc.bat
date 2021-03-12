@set OLDDIR=%CD%

cd C:\DRBC\Scripts\vipt
drbc.pl --action shutdown_standby_servers --wait_for_powered_off
drbc.pl --action shutdown_standby_dc_without_vc

REM CHECK if there are not SANCopy sessions of data from PRIMARY to DR
ECHO Check if there are not SANCopy Sessions from PRIMARY to DR 
cd C:\DRBC\Scripts\Naviseccli
naviseccli_sancopy.pl -m check_failover_sessions

cd C:\DRBC\Scripts\Naviseccli
naviseccli_snapview.pl -m syncandfractureclones

@chdir /d %OLDDIR%
