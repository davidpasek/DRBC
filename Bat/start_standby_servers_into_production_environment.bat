@ECHO OFF

ECHO This is real FAILOVER!!!
ECHO You are going to start standby servers into production environment.
ECHO You confirm (By pressing key 'y') that you 
ECHO ............ known all consequences of DRBC failover
ECHO ............ are allowed to run this operation
ECHO ............ have consulted this operation with management team of your company

SET /P choice="N/y:"
IF "%choice%"=="y" GOTO FAILOVER
echo You have canceled failover procedure.
GOTO END  

:FAILOVER
@set OLDDIR=%CD%

REM SHUTDOWN REPLICATOR WITHOUT VC (COMMUNICATE DIRECTLY WITH ESX SERVERS)
cd C:\DRBC\Scripts\vipt
drbc.pl --action shutdown_replicator_without_vc --wait_for_powered_off

REM Wait for end of SANCopy data from PRIMARY to DR
ECHO Wait for end of SANCopy from PRIMARY to DR 
cd C:\DRBC\Scripts\Naviseccli
naviseccli_sancopy.pl -m check_failover_sessions
ECHO SANCopy finished 

REM SHUTDOWN PRIMARY SERVERS WITHOUT VC (COMMUNICATE DIRECTLY WITH ESX SERVERS)
cd C:\DRBC\Scripts\vipt
drbc.pl --action shutdown_primary_servers_without_vc
drbc.pl --action shutdown_primary_dc_without_vc

REM SHUTDOWN STANDBY SERVERS WITHOUT VC (COMMUNICATE DIRECTLY WITH ESX SERVERS)
cd C:\DRBC\Scripts\vipt
drbc.pl --action shutdown_standby_servers_without_vc
drbc.pl --action shutdown_standby_dc_without_vc

REM TRY SANCopy data from PRIMARY to DR
ECHO Trying SANCopy from PRIMARY to DR 
cd C:\DRBC\Scripts\Naviseccli
naviseccli_sancopy.pl -m check_failover_sessions
naviseccli_sancopy.pl -m failover
naviseccli_sancopy.pl -m check_failover_sessions
ECHO SANCopy finished 

REM Synchronize DR to BC
cd C:\DRBC\Scripts\Naviseccli
naviseccli_snapview.pl -m syncandfractureclones

REM RELOCATE PRIMARY SERVERS INTO STANDBY NETWORKS
REM     WITHOUT VC (COMMUNICATE DIRECTLY WITH ESX SERVERS)
cd C:\DRBC\Scripts\vipt
drbc.pl --action relocate_primary_servers_into_standby_networks_without_vc

REM RELOCATE STANDBY SERVERS INTO APPROPRIATE NETWORKS
REM     WITHOUT VC (COMMUNICATE DIRECTLY WITH ESX SERVERS)
cd C:\DRBC\Scripts\vipt
REM STANDBY DC STAYS IN STANDBY NETWORK
drbc.pl --action relocate_standby_dc_into_standby_network_without_vc
REM OTHER SERVERS MOVE INTO PRODUCTION NETWORKS
drbc.pl --action relocate_standby_servers_into_appropriate_networks_without_vc

REM START STANDBY SERVERS WITHOUT VC (COMMUNICATE DIRECTLY WITH ESX SERVERS)
cd C:\DRBC\Scripts\vipt
REM STANDBY DC STAYS DOWN
drbc.pl --action shutdown_standby_dc_without_vc
REM OTHER SERVERS RUN IN PRODUCTION 
drbc.pl --action start_standby_servers_without_vc

@chdir /d %OLDDIR%

:END
