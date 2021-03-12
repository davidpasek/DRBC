# Configuration hash
sub getConfig {
	my %CONFIG = ();
	#DEBUG 0 = no, 1 = level 1, 2 = level 2, ...
	#$CONFIG{debug} = 1;
	$CONFIG{debug} = 0;
	$CONFIG{debug} = 1;
	#$CONFIG{debug} = 10;
	$CONFIG{script_name} = "navisecli_snapview";
  	$CONFIG{debug_output} = 'c:\\drbc\\log\\drbc.log';

	$CONFIG{naviseccli_command} = '"C:\Program Files\EMC\Navisphere CLI\NaviSECCli.exe"';
	$CONFIG{clariion_ip_address} = '192.168.26.153'; # SPA-1-BS ... EMC Clariion CX3-20c
	$CONFIG{clariion_user} = 'admin';
	$CONFIG{clariion_password} = 'password';
	$CONFIG{clariion_scope} = 'global';
	
	$CONFIG{clonegroup}{max}=3; # Maximum of clone groups

	$CONFIG{clonegroup}{1}{name}="LL_ARCHIVE";
	$CONFIG{clonegroup}{1}{cloneid}="0100000000000000";
	$CONFIG{clonegroup}{1}{consistencygroup}="GROUP_DMS";

	$CONFIG{clonegroup}{2}{name}="LL_DB_DATA";
	$CONFIG{clonegroup}{2}{cloneid}="0100000000000000";
	$CONFIG{clonegroup}{2}{consistencygroup}="GROUP_DMS";

	$CONFIG{clonegroup}{3}{name}="LL_DB_Log";
	$CONFIG{clonegroup}{3}{cloneid}="0100000000000000";
	$CONFIG{clonegroup}{3}{consistencygroup}="GROUP_DMS";

	return %CONFIG;
}
1;
