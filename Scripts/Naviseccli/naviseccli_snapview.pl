use strict;
use warnings;
use IPC::Open2;
use Data::Dumper;
use Getopt::Std;

require '../config/naviseccli_snapview.conf.pl';
require '../common/datetime.pl';
require '../common/debug.pl';

&debug_start();

# -m stands for mode
# -c stands for consistencygroup
#
# options and examples are explained in help section
# #
my %options=();
getopts("m:c:",\%options);

SWITCH: {
	if ( $options{m} && ($options{m} eq "syncclones") ) {
		&debug("Mode " . $options{m} . " is selected");
		if ($options{c}) {
			&debug("Consistency group " . $options{c} );
		}
		&syncclones( "consistencygroup" => $options{c} );
		last;
	}

	if ( $options{m} && ($options{m} eq "fractureclones") ) {
		&debug("Mode " . $options{m} . " is selected");
		if ($options{c}) {
			&debug("Consistency group " . $options{c} );
		}
		&fractureclones( "consistencygroup" => $options{c} );
		last;
	}

	if ( $options{m} && ($options{m} eq "syncandfractureclones") ) {
		&debug("Mode " . $options{m} . " is selected");
		if ($options{c}) {
			&debug("Consistency group " . $options{c} );
		}
		&debug("SYNC CLONES");
		&syncclones( "consistencygroup" => $options{c} );
		&debug("wait 5 sec ...");
		sleep(5);
		&debug("FRACTURE CLONES");
		&fractureclones( "consistencygroup" => $options{c} );
		last;
	}

	# show HELP SECTION
	&debug("No option has been entered");
	print "naviseccli_snapview.pl\n";
	print "Options:\n";
	print "  -m syncclones (synchronize all clones from config)\n";
	print "  -m syncclones -c [consistencygroup] (synchronize clones belongs into [consistencygroup])\n";
	print "  -m fractureclones (consistent fracture of all clones from config)\n";
	print "  -m fractureclones -c [consistencygroup] (consistent fracture of clones belongs into [consistencygroup])\n";
	print "  -m syncandfractureclones (synchronize and consistent fracture of all clones from config)\n";
	print "  -m syncandfractureclones -c [consistencygroup] (synchronize and consistent fracture of clones belongs into [consistencygroup])\n";
	print "\nexamples: \n";
	print "  naviseccli.pl -m syncclones -c A (consistent fracture of clones from config from consistencygroup A)\n";
	print "  naviseccli.pl -m fractureclones -c A (consistent fracture of clones from config from consistencygroup A)\n";
	print "  naviseccli.pl -m syncandfractureclones -c A (consistent fracture of clones from config from consistencygroup A)\n";
}

&debug_end();
exit;

# naviseccli_syncclones
# INPUT: params = { consistencygroup => "GROUP", }
# OUTPUT: 0/1 - fail/success
sub syncclones {
	my %params = @_;

	my %config = &getConfig();
        my $i;
	for $i (1..$config{clonegroup}{max}) {
		my $message;
		my $clonegroup_name;
		my $clonegroup_cloneid;
		my $clonegroup_consistencygroup;

		$message = "CloneGroup $i:";
		if ($config{clonegroup}{$i}{name}) {
			$clonegroup_name =  $config{clonegroup}{$i}{name};
			$message .= " Name: " . $config{clonegroup}{$i}{name};
		}
		if ($config{clonegroup}{$i}{cloneid}) {
			$clonegroup_cloneid =  $config{clonegroup}{$i}{cloneid};
			$message .= " Cloneid: " . $config{clonegroup}{$i}{cloneid};
		}

		if ($config{clonegroup}{$i}{consistencygroup}) {
			$clonegroup_consistencygroup =  $config{clonegroup}{$i}{consistencygroup};
			$message .= " Consistency group: " . $config{clonegroup}{$i}{consistencygroup};
		}

		# check if clongroup belongs into consistency group
		if ( $params{consistencygroup} && ($params{consistencygroup} ne $clonegroup_consistencygroup) ) {
			next; # clone is not from required consistency group
		}

		if ($clonegroup_name && $clonegroup_cloneid) {
			$message .= " run syncclone";
			&syncclone( "clonegroup_name" => $clonegroup_name, "clonegroup_cloneid" => $clonegroup_cloneid );
		}

		if ($config{debug}) { 
			&debug($message, 1);
		}
		
	}
	return 1;
}

# naviseccli_fractureclones
# INPUT: params = { consistencygroup => "GROUP", }
# OUTPUT: 0/1 - fail/success
sub fractureclones {
	my %params = @_;

	my %config = &getConfig();
        my $i;
	my $all_clones_are_synchronized = 0; # false
	my @synchronized_clonegroup_indexes = (); # indexes from config hash of clonegroups

	# Wait until all clones are in synchronized state
	my $waiting_rotation = 0;
 	until ($all_clones_are_synchronized) {
		$waiting_rotation = $waiting_rotation + 1;
		$all_clones_are_synchronized = 1; # I hope all clones are synchronized
		undef @synchronized_clonegroup_indexes; # clear alocated memory
		@synchronized_clonegroup_indexes = (); # clear indexes of synchronized clonegroups
		&debug("Check clones if all are in synchronized state");

		for $i (1..$config{clonegroup}{max}) {
			my $message;
			my $clonegroup_name;
			my $clonegroup_cloneid;
			my $clonegroup_consistencygroup;

			$message = "CloneGroup $i:";
			if ($config{clonegroup}{$i}{name}) {
				$clonegroup_name =  $config{clonegroup}{$i}{name};
				$message .= " Name: " . $config{clonegroup}{$i}{name};
			}
			if ($config{clonegroup}{$i}{cloneid}) {
				$clonegroup_cloneid =  $config{clonegroup}{$i}{cloneid};
				$message .= " Cloneid: " . $config{clonegroup}{$i}{cloneid};
			}

			if ($config{clonegroup}{$i}{consistencygroup}) {
				$clonegroup_consistencygroup =  $config{clonegroup}{$i}{consistencygroup};
				$message .= " Consistency group: " . $config{clonegroup}{$i}{consistencygroup};
			}

			# check if belongs into consistency group
			if ( $params{consistencygroup} && ($params{consistencygroup} ne $clonegroup_consistencygroup) ) {
				next; # clone is not from required consistency group
			}

			
			if (!$clonegroup_name || !$clonegroup_cloneid) {
				next; # clone hasn't name and cloneid
			}

			# check clone state
			$config{clonegroup}{$i}{clonestate} = &checkclonestate("clonegroup_name" => $clonegroup_name);
			if ( $config{clonegroup}{$i}{clonestate} ) {
				$message .= " State: Synchronized";
				push @synchronized_clonegroup_indexes, $i; # put index of synchronized clonegroup into array
			} else {
				$all_clones_are_synchronized = 0; # there is non synchronized clone
				$message .= " State: !!! NOT SYNCHRONIZED !!!";
			} 

			&debug($message);

		} # end for

		# if all clones aren't synchronized wait 5 seconds and check it again
		if (!$all_clones_are_synchronized) {
			&debug("Some clones are not synchronized ... rotation $waiting_rotation ... wait 15 sec and try again.");
			sleep(15);
		}

	} # wait until all clones are synchronized

	if (scalar @synchronized_clonegroup_indexes == 0) {
		&debug("No clones have been found.");
		return 0; # return fail
	}

	&debug("All folowing clones are synchronized.");

	# consisten fracture off following clons
	my $cmd;
	$cmd = $config{naviseccli_command} . " -h " . $config{clariion_ip_address} . " -User " . $config{clariion_user};
	$cmd.= " -Password " . $config{clariion_password} . " -Scope " . $config{clariion_scope} . " snapview ";
        $cmd.= " -consistentfractureclones -CloneGroupNameCloneId";
	foreach $i (@synchronized_clonegroup_indexes) {
		$cmd .= " " . $config{clonegroup}{$i}{name} . " " . $config{clonegroup}{$i}{cloneid};
		&debug($config{clonegroup}{$i}{name} . " - " . $config{clonegroup}{$i}{cloneid});
	}
	&debug("COMMAND:" . $cmd, 10);

	local(*READ, *WRITE);
	my $pid = open2(\*READ, \*WRITE, $cmd);
	print WRITE "y\n";
	close(WRITE);

	my @output = <READ>;
	close(READ);
	my $output = join('',@output);
	&debug("OUTPUT:" . $output, 10);

	&debug("Clones are fractured.");

	return 1;
}

# syncclone
# %params = { "clonegroup_name" => "LL_Archive", "clonegroup_cloneid" => "0100000000000000" }
# OUTPUT: return 0 - fail, 1 - success
sub syncclone {
	my %params = @_;
	my %config = &getConfig();
	my $cmd;

	$cmd = $config{naviseccli_command} . " -h " . $config{clariion_ip_address} . " -User " . $config{clariion_user};
	$cmd.= " -Password " . $config{clariion_password} . " -Scope " . $config{clariion_scope} . " snapview ";
        $cmd.= " -syncclone -name " . $params{"clonegroup_name"} . " -cloneid " . $params{"clonegroup_cloneid"};	
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

# checkclonestate
# %params = { "clonegroup_name" => "LL_Archive" }
# OUTPUT: return 0 - fail, 1 - synchronized
sub checkclonestate {
	my %params = @_;
	my %config = &getConfig();
	my $cmd;
	my $clone_state = 0; # 0 - fail, 1 - synchronized

	$cmd = $config{naviseccli_command} . " -h " . $config{clariion_ip_address} . " -User " . $config{clariion_user};
	$cmd.= " -Password " . $config{clariion_password} . " -Scope " . $config{clariion_scope} . " snapview ";
        $cmd.= " -listclonegroup -name " . $params{"clonegroup_name"} ;
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

		if ( ($line =~ m/^CloneState:/) && ($line =~ m/Synchronized/) ) {
			$clone_state = 1; # synchronized
		}
	}

	# SUCCESS
	return $clone_state;
}

