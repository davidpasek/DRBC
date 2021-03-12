@ECHO OFF

ECHO This is real FAILBACK!!!
ECHO You are going to start primary servers into production environment.
ECHO You confirm (By pressing key 'y') that you 
ECHO ............ known all consequences of DRBC failback
ECHO ............ are allowed to run this operation
ECHO ............ have consulted this operation with management team of your company

SET /P choice="N/y:"
IF "%choice%"=="y" GOTO FAILBACK
echo You have canceled failover procedure.
GOTO END  

:FAILBACK
@set OLDDIR=%CD%

REM SHUTDOWN REPLICATOR WITHOUT VC (COMMUNICATE DIRECTLY WITH ESX SERVERS)
cd C:\DRBC\Scripts\vipt
drbc.pl --action shutdown_replicator_without_vc

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

REM TRY SANCopy data from BC data TO PRIMARY data
ECHO Trying SANCopy from BC data TO PRIMARY data 
cd C:\DRBC\Scripts\Naviseccli
naviseccli_sancopy.pl -m check_failback_sessions
naviseccli_sancopy.pl -m failback
naviseccli_sancopy.pl -m check_failback_sessions
ECHO SANCopy finished

REM RELOCATE STANDBY SERVERS INTO STANDBY NETWORK
REM     WITHOUT VC (COMMUNICATE DIRECTLY WITH ESX SERVERS)
cd C:\DRBC\Scripts\vipt
drbc.pl --action relocate_standby_dc_into_standby_network_without_vc
drbc.pl --action relocate_standby_servers_into_standby_network_without_vc

REM RELOCATE PRIMARY SERVERS INTO APPROPRIATE NETWORKS
REM     WITHOUT VC (COMMUNICATE DIRECTLY WITH ESX SERVERS)
cd C:\DRBC\Scripts\vipt
drbc.pl --action relocate_primary_servers_into_appropriate_networks_without_vc

REM START PRIMARY SERVERS WITHOUT VC (COMMUNICATE DIRECTLY WITH ESX SERVERS)
cd C:\DRBC\Scripts\vipt
drbc.pl --action start_primary_dc_without_vc
drbc.pl --action start_primary_servers_without_vc

REM START REPLICATOR WITHOUT VC (COMMUNICATE DIRECTLY WITH ESX SERVERS)
cd C:\DRBC\Scripts\vipt
drbc.pl --action start_replicator_without_vc

@chdir /d %OLDDIR%

:END
