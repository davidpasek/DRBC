# Configuration hash
sub getConfig {
	my %CONFIG = ();
	#DEBUG 0 = no, 1 = level 1, 2 = level 2, ...
	#$CONFIG{debug} = 1;
	$CONFIG{debug} = 0;
	$CONFIG{debug} = 1;
	#$CONFIG{debug} = 10;
	$CONFIG{script_name} = "navisecli_sancopy";
  	$CONFIG{debug_output} = 'c:\\drbc\\log\\drbc.log';

	$CONFIG{naviseccli_command} = '"C:\Program Files\EMC\Navisphere CLI\NaviSECCli.exe"';
	$CONFIG{primary_clariion_ip_address} = '192.168.26.150';
	$CONFIG{primary_clariion_user} = 'admin';
	$CONFIG{primary_clariion_password} = 'password';
	$CONFIG{primary_clariion_scope} = 'global';
	
	$CONFIG{backup_clariion_ip_address} = '192.168.26.152';
	$CONFIG{backup_clariion_user} = 'admin';
	$CONFIG{backup_clariion_password} = 'password';
	$CONFIG{backup_clariion_scope} = 'global';

	$CONFIG{sancopy_linkbw} = 100;
	
	$CONFIG{lun}{max}=3; # Maximum of LUNs

	# LL_DB_DATA
	$CONFIG{lun}{1}{sancopy_failback_session_name}="REVERZ_LL_DB_DATA";
	$CONFIG{lun}{1}{sancopy_failover_session_name}="clariion_RMINC-CK200081300279_0300-080917103246";
	$CONFIG{lun}{1}{group}="GROUP";

	# LL_DB_LOG
	$CONFIG{lun}{2}{sancopy_failback_session_name}="REVERZ_LL_DB_LOG";
	$CONFIG{lun}{2}{sancopy_failover_session_name}="clariion_RMINC-CK200081300279_0200-080917103246";
	$CONFIG{lun}{2}{group}="GROUP";

	# LL_ARCHIVE
	$CONFIG{lun}{3}{sancopy_failback_session_name}="REVERZ_LL_ARCHIVE";
	$CONFIG{lun}{3}{sancopy_failover_session_name}="clariion_RMINC-CK200081300279_0100-080916162014";
	$CONFIG{lun}{3}{group}="GROUP";

	return %CONFIG;
}
1;
