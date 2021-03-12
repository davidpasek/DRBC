@ECHO OFF
@set OLDDIR=%CD%
cd C:\DRBC\bat

REM ########################################
REM # MAIN MENU
REM ########################################
:MAIN_MENU
CLS
ECHO *******************************************************************************
ECHO * DISASTER RECOVERY AND BUSINESS CONTINUITY - MAIN MENU                       *
ECHO *******************************************************************************
ECHO * 1) Test Environment Menu                                                    *
ECHO * 2) Backup and Recovery Menu                                                 *
ECHO * 3) Real Disaster Menu                                                       *
ECHO * --------------------------------------------------------------------------- *
ECHO * 0) Quit this menu                                                           *
ECHO *******************************************************************************

REM ########################################
REM # SELECT MENU CHOICE
REM ########################################
SET /P choice="Choose option:"

IF "%choice%"=="0" GOTO END
IF "%choice%"=="1" GOTO TEST_MENU
IF "%choice%"=="2" GOTO BACKUP_MENU
IF "%choice%"=="3" GOTO DISASTER_MENU

ECHO Wrong choise. Choose again.
PAUSE
GOTO MAIN_MENU

REM ########################################
REM # TEST MENU
REM ########################################
:TEST_MENU
ECHO *******************************************************************************
ECHO * DISASTER RECOVERY AND BUSINESS CONTINUITY - TEST ENVIRONMENT MENU           *
ECHO *******************************************************************************
ECHO * 1) Synchronize Disk Clones - Synch DR disks to BC disks (refresh BC data)   *
ECHO * 2) Start Standby Servers in Isolated Environment (test environment)         *
ECHO * 3) Shutdown Standby Servers in Isolated Environment (test environment)      *
ECHO * --------------------------------------------------------------------------- *
ECHO * 0) Quit to main menu                                                        *
ECHO *******************************************************************************

REM ########################################
REM # SELECT MENU CHOICE
REM ########################################
SET /P choice="Choose option (0-3):"

IF "%choice%"=="0" GOTO MAIN_MENU
IF "%choice%"=="1" GOTO SYNCH_TEST
IF "%choice%"=="2" GOTO START_TEST
IF "%choice%"=="3" GOTO STOP_TEST

ECHO Wrong choise. Choose again.
PAUSE
GOTO TEST_MENU

REM ########################################
REM # DISASTER MENU
REM ########################################
:DISASTER_MENU
CLS
ECHO *******************************************************************************
ECHO * DISASTER RECOVERY AND BUSINESS CONTINUITY - DISASTER MENU                   *
ECHO *******************************************************************************
ECHO * 1) FAILOVER - Primary Site to Backup Site (VC is not needed)                *
ECHO * --------------------------------------------------------------------------- *
ECHO * 2) FAILBACK - Backup Site to Primary site (VC is not needed)                *
ECHO * 3) FAILBACK WITHOUT SANCOPY - Backup Site to Primary site (VC is not needed)*
ECHO * --------------------------------------------------------------------------- *
ECHO * 0) Quit to main menu                                                        *
ECHO *******************************************************************************

REM ########################################
REM # SELECT MENU CHOICE
REM ########################################
SET /P choice="Choose option:"

IF "%choice%"=="0" GOTO MAIN_MENU
IF "%choice%"=="1" GOTO START_FAILOVER
IF "%choice%"=="2" GOTO START_FAILBACK
IF "%choice%"=="3" GOTO START_FAILBACK_WITHOUT_SANCOPY

ECHO Wrong choise. Choose again.
PAUSE
GOTO DISASTER_MENU

REM ########################################
REM # BACKUP AND RECOVERY MENU
REM ########################################
:BACKUP_MENU
CLS
ECHO *******************************************************************************
ECHO * BACKUP AND RECOVERY MENU                                                    *
ECHO *******************************************************************************
ECHO * 1) Backup Virtual Machines from Primary Site                                *
ECHO * 2) Restore Virtual Machines into Backup Site                                *
ECHO * --------------------------------------------------------------------------- *
ECHO * 0) Quit to main menu                                                        *
ECHO *******************************************************************************

REM ########################################
REM # SELECT MENU CHOICE
REM ########################################
SET /P choice="Choose option:"

IF "%choice%"=="0" GOTO MAIN_MENU
IF "%choice%"=="1" GOTO BACKUP_VRANGER_IMAGES
IF "%choice%"=="2" GOTO RESTORE_VRANGER_IMAGES

ECHO Wrong choise. Choose again.
PAUSE
GOTO BACKUP_MENU

REM @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
REM @@@@                    FUNCTIONS                                            @@@@
REM @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

REM ########################################
REM # SYNCHRONIZE DISK CLONES - TEST MENU
REM ########################################
:SYNCH_TEST
ECHO Synchronizing DR and BC disk on disk array on backup site ...
CALL synch_clonegroups_dr_bc.bat
PAUSE
CLS
GOTO TEST_MENU

REM ########################################
REM # RUN STANDBY SERVERS IN ISOLATED ENVIRONMENT
REM ########################################
:START_TEST
ECHO Running standby servers in isolated environment on backup site
CALL start_standby_servers_in_isolated_environment.bat
PAUSE
CLS
GOTO TEST_MENU

REM ########################################
REM # STOP STANDBY SERVERS IN ISOLATED ENVIRONMENT
REM ########################################
:STOP_TEST
ECHO Stoping standby servers in isolated environment on backup site
CALL shutdown_standby_servers_in_isolated_environment.bat
PAUSE
CLS
GOTO TEST_MENU

REM ########################################
REM # RESTORE 
REM ########################################
:RESTORE_VRANGER_IMAGES
ECHO Do you really want to restore last vRanger images into backup site?
SET /P choice="N/y:"
IF "%choice%"=="y" GOTO RESTORE_VRANGER_IMAGES2
GOTO BACK_TO_BACKUP_MENU
:RESTORE_VRANGER_IMAGES2
ECHO Restore Virtual Machines Images into Backup Site
CALL restore_virtual_machines_into_backup_site.bat
PAUSE
CLS
GOTO BACKUP_MENU

REM ########################################
REM # BACKUP
REM ########################################
:BACKUP_VRANGER_IMAGES
ECHO Do you really want to backup Virtual Machines from primary site?
SET /P choice="N/y:"
IF "%choice%"=="y" GOTO BACKUP_VRANGER_IMAGES2
GOTO BACK_TO_BACKUP_MENU
:BACKUP_VRANGER_IMAGES2
ECHO Backup Virtual Machines Images from Backup Site
CALL backup_virtual_machines_from_primary_site.bat
PAUSE
CLS
GOTO BACKUP_MENU

REM ########################################
REM # REAL DRBC FAIL OVER FROM PRIMARY SITE TO BACKUP SITE
REM ########################################
:START_FAILOVER
ECHO Do you really want to start standby servers into production environment?
SET /P choice="N/y:"
IF "%choice%"=="y" GOTO START_FAILOVER2
GOTO BACK_TO_DISASTER_MENU  
:START_FAILOVER2
ECHO Are you absolutely sure that there is no other way then start up DRBC environment?
SET /P choice="N/y:"
IF "%choice%"=="y" GOTO START_FAILOVER3
GOTO BACK_TO_DISASTER_MENU  
:START_FAILOVER3
CALL start_standby_servers_into_production_environment.bat
PAUSE
GOTO DISASTER_MENU

REM ########################################
REM # REAL DRBC FAIL BACK FROM BACKUP SITE TO PRIMARY SITE
REM ########################################
:START_FAILBACK
ECHO Do you really want start primary servers into production environment?
SET /P choice="N/y:"
IF "%choice%"=="y" GOTO START_FAILBACK2
GOTO BACK_TO_DISASTER_MENU  
:START_FAILBACK2
ECHO Are you absolutely sure that there is everything ready for fail-back?
SET /P choice="N/y:"
IF "%choice%"=="y" GOTO START_FAILBACK3
GOTO BACK_TO_DISASTER_MENU  
:START_FAILBACK3
CALL start_primary_servers_into_production_environment.bat
PAUSE
GOTO DISASTER_MENU

REM ########################################
REM # REAL DRBC FAIL BACK FROM BACKUP SITE TO PRIMARY SITE WITHOUT SANCOPY
REM ########################################
:START_FAILBACK_WITHOUT_SANCOPY
ECHO Do you really want start primary servers into production environment?
SET /P choice="N/y:"
IF "%choice%"=="y" GOTO START_FAILBACK_SANCOPY2
GOTO BACK_TO_DISASTER_MENU  
:START_FAILBACK_SANCOPY2
ECHO Are you absolutely sure that there is everything ready for fail-back?
SET /P choice="N/y:"
IF "%choice%"=="y" GOTO START_FAILBACK_SANCOPY3
GOTO BACK_TO_DISASTER_MENU  
:START_FAILBACK_SANCOPY3
CALL start_primary_servers_into_production_environment_without_sancopy.bat
PAUSE
GOTO DISASTER_MENU

REM ########################################
REM # BACK TO TEST MENU
REM ########################################
:BACK_TO_TEST_MENU
ECHO You didn't confirm the option. You'll be transfered back to menu.
pause
GOTO TEST_MENU

REM ########################################
REM # BACK TO BACKUP MENU
REM ########################################
:BACK_TO_BACKUP_MENU
ECHO You didn't confirm the option. You'll be transfered back to menu.
pause
GOTO BACKUP_MENU

:END
@chdir /d %OLDDIR%
