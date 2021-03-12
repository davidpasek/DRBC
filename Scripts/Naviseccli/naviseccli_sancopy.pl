use strict;
use warnings;
use IPC::Open2;
use Data::Dumper;
use Getopt::Std;

require '../config/naviseccli_sancopy.conf.pl';
require '../common/datetime.pl';
require '../common/debug.pl';

# -m stands for mode (sancopyluns)
#
# options and examples are explained in help section
# #
my %options=();
getopts("m:",\%options);

SWITCH: {
	if ( $options{m} && ($options{m} eq "failover") ) {
		&debug("Mode " . $options{m} . " is selected");
		&sancopy_failover();
		last;
	}

	if ( $options{m} && ($options{m} eq "failback") ) {
		&debug("Mode " . $options{m} . " is selected");
		&sancopy_failback();
		last;
	}

	if ( $options{m} && ($options{m} eq "check_failover_sessions") ) {
		&debug("Mode " . $options{m} . " is selected");
		&sancopy_failover_check_sessions_state();
		last;
	}

	if ( $options{m} && ($options{m} eq "check_failback_sessions") ) {
		&debug("Mode " . $options{m} . " is selected");
		&sancopy_failback_check_sessions_state();
		last;
	}

	# show HELP SECTION
	print "naviseccli_sancopy.pl\n";
	print "Options:\n";
	print "  -m failover (PRIMARY -> DR)\n";
	print "  -m failback (DR -> PRIMARY)\n";
	print "  -m check_failover_sessions\n";
	print "  -m check_failback_sessions\n";
	print "\nexamples: \n";
	print "  naviseccli_sancopy.pl -m failover\n";
}

exit;

# sancopy_failover
# INPUT: params = { group => "GROUP-NAME", }
# OUTPUT: 0/1 - fail/success
sub sancopy_failover {
	my %params = @_;

	my %config = &getConfig();
        my $i;
	for $i (1..$config{lun}{max}) {
		my $clariion_ip_address;
		my $clariion_scope;
		my $clariion_user;
		my $clariion_password;
		my $sancopy_session_name;
		my $group;

		&debug("LUN $i:");
		if ($config{primary_clariion_ip_address}) {
			$clariion_ip_address = $config{primary_clariion_ip_address};
			&debug("Clariion IP address: " . $clariion_ip_address);
		}
		if ($config{primary_clariion_scope}) {
			$clariion_scope = $config{primary_clariion_scope};
			&debug("Clariion Scope: " . $clariion_scope);
		}
		if ($config{primary_clariion_user}) {
			$clariion_user = $config{primary_clariion_user};
			&debug("Clariion user: " . $clariion_user);
		}
		if ($config{primary_clariion_password}) {
			$clariion_password = $config{primary_clariion_password};
			#&debug("Clariion password: " . $clariion_password);
		}
		if ($config{lun}{$i}{sancopy_failover_session_name}) {
			$sancopy_session_name =  $config{lun}{$i}{sancopy_failover_session_name};
			&debug("Sancopy failover session name: " . $sancopy_session_name);
		}
		if ($config{lun}{$i}{group}) {
			$group =  $config{lun}{$i}{group};
			&debug("Group: " . $group);
		}

		# check if lun belongs into required group
		if ( $params{group} && ($params{group} ne $group) ) {
			next; # lun is not from required group
		}

		if ($clariion_ip_address && $clariion_scope && $clariion_user && $clariion_password && $sancopy_session_name) {
			&debug("Start sancopy session");
			&sancopy_session_start("sancopysessionname" => $sancopy_session_name, 
				               "clariion_ip_address" => $clariion_ip_address,
				               "clariion_scope" => $clariion_scope,
				               "clariion_user" => $clariion_user,
				               "clariion_password" => $clariion_password,
				       );
		} else {
			&debug("Mandatory config parameters are missing");
		}

	}

	return 1;
}

# sancopy_failback
# INPUT: params = { group => "GROUP", }
# OUTPUT: 0/1 - fail/success
sub sancopy_failback {
	my %params = @_;

	my %config = &getConfig();
        my $i;
	for $i (1..$config{lun}{max}) {
		my $clariion_ip_address;
		my $clariion_scope;
		my $clariion_user;
		my $clariion_password;
		my $sancopy_session_name;
		my $group;

		&debug("LUN $i:");
		if ($config{backup_clariion_ip_address}) {
			$clariion_ip_address = $config{backup_clariion_ip_address};
			&debug("Clariion IP address: " . $clariion_ip_address);
		}
		if ($config{backup_clariion_scope}) {
			$clariion_scope = $config{backup_clariion_scope};
			&debug("Clariion Scope: " . $clariion_scope);
		}
		if ($config{backup_clariion_user}) {
			$clariion_user = $config{backup_clariion_user};
			&debug("Clariion user: " . $clariion_user);
		}
		if ($config{backup_clariion_password}) {
			$clariion_password = $config{backup_clariion_password};
			#&debug("Clariion password: " . $clariion_password);
		}
		if ($config{lun}{$i}{sancopy_failback_session_name}) {
			$sancopy_session_name =  $config{lun}{$i}{sancopy_failback_session_name};
			&debug("Sancopy failover session name: " . $sancopy_session_name);
		}
		if ($config{lun}{$i}{group}) {
			$group =  $config{lun}{$i}{group};
			&debug("Group: " . $group);
		}

		# check if lun belongs into required group
		if ( $params{group} && ($params{group} ne $group) ) {
			next; # lun is not from required group
		}

		if ($clariion_ip_address && $clariion_scope && $clariion_user && $clariion_password && $sancopy_session_name) {
			&debug("Start sancopy session");
			&sancopy_session_start("sancopysessionname" => $sancopy_session_name, 
				               "clariion_ip_address" => $clariion_ip_address,
				               "clariion_scope" => $clariion_scope,
				               "clariion_user" => $clariion_user,
				               "clariion_password" => $clariion_password,
				       );
		} else {
			&debug("Mandatory config parameters are missing");
		}

	}

	return 1;
}

# sancopy_failover_check_sessions_state();
# INPUT: params = { group => "GROUP", }
# OUTPUT: 0/1 - fail/success
sub sancopy_failover_check_sessions_state {
	my %params = @_;
	my $all_session_state_complete = 0; # false

	my %config = &getConfig();
        my $i;

	# Wait until all sessions are in Complete state
	my $waiting_rotation = 0;
 	until ($all_session_state_complete) {
		$waiting_rotation = $waiting_rotation + 1;
		$all_session_state_complete = 1; # I hope all sessions are Completed

		for $i (1..$config{lun}{max}) {
			my $clariion_ip_address;
			my $clariion_scope;
			my $clariion_user;
			my $clariion_password;
			my $sancopy_session_name;
			my $group;
			my $session_state;

			&debug("LUN $i:");
			if ($config{primary_clariion_ip_address}) {
				$clariion_ip_address = $config{primary_clariion_ip_address};
				&debug("Clariion IP address: " . $clariion_ip_address);
			}
			if ($config{primary_clariion_scope}) {
				$clariion_scope = $config{primary_clariion_scope};
				&debug("Clariion Scope: " . $clariion_scope);
			}
			if ($config{primary_clariion_user}) {
				$clariion_user = $config{primary_clariion_user};
				&debug("Clariion user: " . $clariion_user);
			}
			if ($config{primary_clariion_password}) {
				$clariion_password = $config{primary_clariion_password};
				#&debug("Clariion password: " . $clariion_password);
			}
			if ($config{lun}{$i}{sancopy_failover_session_name}) {
				$sancopy_session_name =  $config{lun}{$i}{sancopy_failover_session_name};
				&debug("Sancopy failover session name: " . $sancopy_session_name);
			}
			if ($config{lun}{$i}{group}) {
				$group =  $config{lun}{$i}{group};
				&debug("Group: " . $group);
			}

			# check if lun belongs into required group
			if ( $params{group} && ($params{group} ne $group) ) {
				next; # lun is not from required group
			}

			if ($clariion_ip_address && $clariion_scope && $clariion_user && $clariion_password && $sancopy_session_name) {
				&debug("Get sancopy session state");
				$session_state = &sancopy_check_session_state("sancopysessionname" => $sancopy_session_name, 
						       "clariion_ip_address" => $clariion_ip_address,
						       "clariion_scope" => $clariion_scope,
						       "clariion_user" => $clariion_user,
						       "clariion_password" => $clariion_password,
					       );

				if ($session_state) {
					&debug("Session State: Completed");
				} else {		
					&debug("Session State: Active");
					$all_session_state_complete = 0;
				}

			} else {
				&debug("Mandatory config parameters are missing");
			}

		} # end for

		# if all sessions aren't completed wait 15 seconds and check it again
		if (!$all_session_state_complete) {
			&debug("Some sessions are not completed ... rotation $waiting_rotation ... wait 15 sec and try again.");
			sleep(15);
		}

	} # end until

	return 1;
}

# sancopy_failback_check_sessions_state();
# INPUT: params = { group => "GROUP", }
# OUTPUT: 0/1 - fail/success
sub sancopy_failback_check_sessions_state {
	my %params = @_;
	my $all_session_state_complete = 0; # false

	my %config = &getConfig();
        my $i;

	# Wait until all sessions are in Complete state
	my $waiting_rotation = 0;
 	until ($all_session_state_complete) {
		$waiting_rotation = $waiting_rotation + 1;
		$all_session_state_complete = 1; # I hope all sessions are Completed

		for $i (1..$config{lun}{max}) {
			my $clariion_ip_address;
			my $clariion_scope;
			my $clariion_user;
			my $clariion_password;
			my $sancopy_session_name;
			my $group;
			my $session_state;

			&debug("LUN $i:");
			if ($config{backup_clariion_ip_address}) {
				$clariion_ip_address = $config{backup_clariion_ip_address};
				&debug("Clariion IP address: " . $clariion_ip_address);
			}
			if ($config{backup_clariion_scope}) {
				$clariion_scope = $config{backup_clariion_scope};
				&debug("Clariion Scope: " . $clariion_scope);
			}
			if ($config{backup_clariion_user}) {
				$clariion_user = $config{backup_clariion_user};
				&debug("Clariion user: " . $clariion_user);
			}
			if ($config{backup_clariion_password}) {
				$clariion_password = $config{backup_clariion_password};
				#&debug("Clariion password: " . $clariion_password);
			}
			if ($config{lun}{$i}{sancopy_failback_session_name}) {
				$sancopy_session_name =  $config{lun}{$i}{sancopy_failback_session_name};
				&debug("Sancopy failback session name: " . $sancopy_session_name);
			}
			if ($config{lun}{$i}{group}) {
				$group =  $config{lun}{$i}{group};
				&debug("Group: " . $group);
			}

			# check if lun belongs into required group
			if ( $params{group} && ($params{group} ne $group) ) {
				next; # lun is not from required group
			}

			if ($clariion_ip_address && $clariion_scope && $clariion_user && $clariion_password && $sancopy_session_name) {
				&debug("Get sancopy session state");
				$session_state = &sancopy_check_session_state("sancopysessionname" => $sancopy_session_name, 
						       "clariion_ip_address" => $clariion_ip_address,
						       "clariion_scope" => $clariion_scope,
						       "clariion_user" => $clariion_user,
						       "clariion_password" => $clariion_password,
					       );

				if ($session_state) {
					&debug("Session State: Completed");
				} else {		
					&debug("Session State: Active !!!");
					$all_session_state_complete = 0;
				}

			} else {
				&debug("Mandatory config parameters are missing");
			}

		} # end for
		
		# if all sessions aren't completed wait 15 seconds and check it again
		if (!$all_session_state_complete) {
			&debug("Some sessions are not completed ... rotation $waiting_rotation ... wait 15 sec and try again.");
			sleep(15);
		}

	} # end until

	return 1;
}

# sancopy_session_start
# %params = { "sancopysessionname" => "clariion_RMINC-CK200081300279_0100-080916162014", 
#             "clariion_ip_address" => "192.168.26.150",
#             "clariion_scope" => "0",
#             "clariion_user" => "admin",
#             "clariion_password" => "password",
#             }
# OUTPUT: return 0 - fail, 1 - success
sub sancopy_session_start {
	my %params = @_;
	my %config = &getConfig();
	my $cmd;

	$cmd = $config{naviseccli_command} . " -h " . $params{clariion_ip_address} . " -User " . $params{clariion_user};
	$cmd.= " -Password " . $params{clariion_password} . " -Scope " . $params{clariion_scope} ;
        $cmd.= " sancopy ";
	$cmd.= " -start ";
	$cmd.= " -name " . $params{sancopysessionname};
	&debug("COMMAND:" . $cmd, 10);

	local(*READ, *WRITE);
	my $pid = open2(\*READ, \*WRITE, $cmd);
	print WRITE "y\n";
	close(WRITE);

	my @output = <READ>;
	close(READ);
	my $output = join('',@output);
	&debug("OUTPUT:" . $output, 10);

	# SUCCESS
	return 1;
}

# sancopy_check_session_state
# %params = { "sancopysessionname" => "clariion_RMINC-CK200081300279_0100-080916162014", 
#             "clariion_ip_address" => "192.168.26.150",
#             "clariion_scope" => "0",
#             "clariion_user" => "admin",
#             "clariion_password" => "password",
#             }
# OUTPUT: return 0 - fail, 1 - complete
sub sancopy_check_session_state {
	my %params = @_;
	my %config = &getConfig();
	my $cmd;
	my $session_state = 0; # 0 - fail, 1 - complete

	$cmd = $config{naviseccli_command} . " -h " . $params{clariion_ip_address} . " -User " . $params{clariion_user};
	$cmd.= " -Password " . $params{clariion_password} . " -Scope " . $params{clariion_scope} ;
        $cmd.= " sancopy ";
	$cmd.= " -info ";
	$cmd.= " -name " . $params{sancopysessionname};
	&debug("COMMAND:" . $cmd, 10);

	local(*READ, *WRITE);
	my $pid = open2(\*READ, \*WRITE, $cmd);
	if (!$pid) {
		# FAIL
		return 0;
	}
	close(WRITE);

	my @output = <READ>;
	close(READ);
	waitpid($pid,0);
	
	my $output = join('',@output);
	&debug("OUTPUT:\n" . $output, 10);

	my $line;
	foreach $line (@output) {
		chomp($line);

		if ( ($line =~ m/^Session Status:/) && ($line =~ m/Complete/) ) {
			$session_state = 1; # Complete
		}
	}

	# SUCCESS
	return $session_state;
}
