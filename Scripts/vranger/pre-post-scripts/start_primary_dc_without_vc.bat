@ECHO OFF
set OLDDIR=%CD%

cd C:\DRBC\Scripts\vipt
drbc.pl --action start_primary_dc_without_vc

@chdir /d %OLDDIR%