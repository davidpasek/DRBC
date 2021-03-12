# Configuration hash
sub getConfig {
	my %CONFIG = ();
	#DEBUG 1 = yes, 0 = no?
	#$CONFIG{debug} = 0;
	#$CONFIG{debug} = 10;
	$CONFIG{debug} = 1;
	$CONFIG{script_name} = "vranger";
  	$CONFIG{debug_output} = 'c:\\drbc\\log\\drbc.log';

	$CONFIG{vranger_exe}='"c:\program files\vizioncore\esxRanger Professional\esxRangerProCli.exe"';

	$CONFIG{mail_smtp_server}="pluto.home.uw.cz";
	$CONFIG{mail_to}="it\@home.uw.cz";
	$CONFIG{mail_from}="it\@home.uw.cz";

	#$CONFIG{backup_location_mount_cmd}='net use R: \\\\pe2900\vRanger password /USER:administrator';
	#$CONFIG{backup_location_umount_cmd}='net use R: /DELETE';
	#$CONFIG{archive_location_mount_cmd}='net use R: \\\\pe2900\vRanger password /USER:administrator';
	#$CONFIG{archive_location_umount_cmd}='net use R: /DELETE';
	$CONFIG{backup_location}='R:';
	$CONFIG{archive_location}='R:\\Archive';

	$CONFIG{backup_order} = "LL-DB LL-ARCHIVE LL-DC VC ECM_Cache LL-APP-EXT LL-APP-INT LL-ADM-IND ";
	$CONFIG{restore_order} = "LL-DB LL-ARCHIVE LL-DC VC ECM_Cache LL-APP-EXT LL-APP-INT LL-ADM-IND ";

	$CONFIG{VM}{"LL-DB"}{internalname}='LL-DB';
	$CONFIG{VM}{"LL-DB"}{virtualcenter_vm}='vc2://VirtualMachine=vm-310';
	$CONFIG{VM}{"LL-DB"}{drives}='1';
	$CONFIG{VM}{"LL-DB"}{destserver}='esx1-bs.home.uw.cz';
	$CONFIG{VM}{"LL-DB"}{destdatastore}="Datastore1,";
	$CONFIG{VM}{"LL-DB"}{networkname}="ethernet0,VI_STANDBY";

	$CONFIG{VM}{"LL-ARCHIVE"}{internalname}='LL-ARCHIVE';
	$CONFIG{VM}{"LL-ARCHIVE"}{virtualcenter_vm}='vc2://VirtualMachine=vm-312';
	$CONFIG{VM}{"LL-ARCHIVE"}{drives}='1';
	$CONFIG{VM}{"LL-ARCHIVE"}{destserver}='esx1-bs.home.uw.cz';
	$CONFIG{VM}{"LL-ARCHIVE"}{destdatastore}="Datastore1,";
	$CONFIG{VM}{"LL-ARCHIVE"}{networkname}="ethernet0,VI_STANDBY";

	$CONFIG{VM}{"LL-DC"}{internalname}='LL-DC';
	$CONFIG{VM}{"LL-DC"}{virtualcenter_vm}='vc2://VirtualMachine=vm-5008';
	$CONFIG{VM}{"LL-DC"}{drives}='All';
	$CONFIG{VM}{"LL-DC"}{destserver}='esx1-bs.home.uw.cz';
	$CONFIG{VM}{"LL-DC"}{destdatastore}="Datastore2,";
	$CONFIG{VM}{"LL-DC"}{networkname}="ethernet0,VI_STANDBY";
	$CONFIG{VM}{"LL-DC"}{prescript}='c:\\drbc\\scripts\\vranger\\pre-post-scripts\\shutdown_primary_dc_without_vc.bat';
	$CONFIG{VM}{"LL-DC"}{postscript}='c:\\drbc\\scripts\\vranger\\pre-post-scripts\\start_primary_dc_without_vc.bat';

	$CONFIG{VM}{"VC"}{internalname}='VC';
	$CONFIG{VM}{"VC"}{virtualcenter_vm}='vc2://VirtualMachine=vm-26';
	$CONFIG{VM}{"VC"}{drives}='All';
	$CONFIG{VM}{"VC"}{destserver}='esx1-bs.home.uw.cz';
	$CONFIG{VM}{"VC"}{destdatastore}="Datastore2,";
	$CONFIG{VM}{"VC"}{networkname}="ethernet0,VI_STANDBY";

	$CONFIG{VM}{"ECM_Cache"}{internalname}='ECM_Cache';
	$CONFIG{VM}{"ECM_Cache"}{virtualcenter_vm}='vc2://VirtualMachine=vm-8966';
	$CONFIG{VM}{"ECM_Cache"}{drives}='All';
	$CONFIG{VM}{"ECM_Cache"}{destserver}='esx1-bs.home.uw.cz';
	$CONFIG{VM}{"ECM_Cache"}{destdatastore}="Datastore2,";
	$CONFIG{VM}{"ECM_Cache"}{networkname}="ethernet0,VI_STANDBY;ethernet1,VI_STANDBY;ethernet2,VI_STANDBY;ethernet3,VI_STANDBY;";

	$CONFIG{VM}{"LL-APP-EXT"}{internalname}='LL-APP-EXT';
	$CONFIG{VM}{"LL-APP-EXT"}{virtualcenter_vm}='vc2://VirtualMachine=vm-454';
	$CONFIG{VM}{"LL-APP-EXT"}{drives}='All';
	$CONFIG{VM}{"LL-APP-EXT"}{destserver}='esx1-bs.home.uw.cz';
	$CONFIG{VM}{"LL-APP-EXT"}{destdatastore}="Datastore1,";
	$CONFIG{VM}{"LL-APP-EXT"}{networkname}="ethernet0,VI_STANDBY";

	$CONFIG{VM}{"LL-APP-INT"}{internalname}='LL-APP-INT';
	$CONFIG{VM}{"LL-APP-INT"}{virtualcenter_vm}='vc2://VirtualMachine=vm-452';
	$CONFIG{VM}{"LL-APP-INT"}{drives}='All';
	$CONFIG{VM}{"LL-APP-INT"}{destserver}='esx1-bs.home.uw.cz';
	$CONFIG{VM}{"LL-APP-INT"}{destdatastore}="Datastore1,";
	$CONFIG{VM}{"LL-APP-INT"}{networkname}="ethernet0,VI_STANDBY;ethernet1,VI_STANDBY;";

	$CONFIG{VM}{"LL-ADM-IND"}{internalname}='LL-ADM-IND';
	$CONFIG{VM}{"LL-ADM-IND"}{virtualcenter_vm}='vc2://VirtualMachine=vm-466';
	$CONFIG{VM}{"LL-ADM-IND"}{drives}='All';
	$CONFIG{VM}{"LL-ADM-IND"}{destserver}='esx1-bs.home.uw.cz';
	$CONFIG{VM}{"LL-ADM-IND"}{destdatastore}="Datastore1,";
	$CONFIG{VM}{"LL-ADM-IND"}{networkname}="ethernet0,VI_STANDBY;ethernet1,VI_STANDBY;";

	return %CONFIG;
}
1;
