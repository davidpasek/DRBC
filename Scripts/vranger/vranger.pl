use strict;
use warnings;
use IPC::Open2;
use Data::Dumper;
use Getopt::Std;
use Net::SMTP;

require '../config/vranger.conf.pl';
require '../common/datetime.pl';
require '../common/debug.pl';

&debug_start();

# -m stands for mode (backup, restore, check_today_backups, check_today_backups_for_restore, delete_old) 
#
# options and examples are explained in help section
# 
my %options=();
getopts("m:d:",\%options);

my $errorlevel = 0;
SWITCH: {

	if ( $options{m} && ($options{m} eq "backup") ) {
		&debug("Mode " . $options{m} . " is selected");
		&mountArchiveLocation();
		&backupVMs();
		&umountArchiveLocation();
		last;
	}

	if ( $options{m} && ($options{m} eq "check_today_backups") ) {
		&debug("Mode " . $options{m} . " is selected");
		&mountArchiveLocation();
		if (!&checkTodayBackup(what_check=>"all_backups")) {
			$errorlevel = 1;
			&debug("ERROR LEVEL: $errorlevel");
			# notify admin by email
			&mailNotify(subject=> "DRBC/VRANGER.PL", message=>"Some backups are not OK.");
		}
		&umountArchiveLocation();
		last;
	}

	if ( $options{m} && ($options{m} eq "check_today_backups_for_restore") ) {
		&debug("Mode " . $options{m} . " is selected");
		&mountArchiveLocation();
		if (!&checkTodayBackup(what_check=>"backups_for_restore")) {
			$errorlevel = 1;
			# notify admin by email
			&mailNotify(subject=> "DRBC/VRANGER.PL", message=>"Some backups are not OK.");
		}
		&umountArchiveLocation();
		last;
	}

	if ( $options{m} && ($options{m} eq "restore") ) {
		&debug("Mode " . $options{m} . " is selected");
		&mountArchiveLocation();
		&restoreVMs();
		&umountArchiveLocation();
		last;
	}

	if ( $options{m} && ($options{m} eq "deleteold") ) {
		if ( !$options{d} ) {
			&debug("Set days to 7");
			$options{d} = 7;
		}
		&debug("Mode " . $options{m} . " is selected");
		&debug("Delete files older then " . $options{d} . " days.");
		&mountArchiveLocation();
		&deleteold( "olderthan" => $options{d} );
		&umountArchiveLocation();
		last;
	}

	# show HELP SECTION
	print "vranger.pl\n";
	print "Options:\n";
	print "  -m backup (backup VM images to backup directory)\n";
	print "  -m restore (restore today's VM images from backup directory)\n";
	print "  -m check_today_backups (check today's VM images backups)\n";
	print "  -m check_today_backups_for_restore (check today's VM images backups configured for automated restore)\n";
	print "  -m deleteold (delete files in archive directory older then 7 days)\n";
	print "  -m deleteold -d <days> (delete files in archive directory older then <days> days)\n";
}

&debug("ERROR LEVEL: $errorlevel");
&debug_end();
exit $errorlevel;

# Mail Notification
# INPUT: params = { 
# 		subject => "DRBC/VRANGER.PL", 
# 		message => "Some backup are not OK.",
# 		}
# OUTPUT: 0/1 .. failure/success
sub mailNotify {
	my %params = @_;
	my %config = &getConfig();


	my $relay=$config{mail_smtp_server};
	my $to=$config{mail_to};
	my $from=$config{mail_from};

	if ( (!$relay) || (!$to) || (!$from) ) {
		&debug("No mail notification.");
		&debug("Mail is not configured ... \$CONFIG{mail_smtp_server,mail_to,mail_from}");
		return 0;
	}

	&debug("Sending mail notification to $to ...");
	my $subject=$params{subject};
	my $message=$params{message};
  
	my $smtp = Net::SMTP->new($relay);
        if (!$smtp) {
		&debug("Cannot connect to smtp server $relay");
	}

	$smtp->mail($from);
	$smtp->to($to);
	$smtp->data();

	# Send the header.
	$smtp->datasend("To: $to\n");
	$smtp->datasend("From: $from\n");
	$smtp->datasend("Subject: $subject\n");
	$smtp->datasend($message);
	$smtp->dataend();                     # Finish sending the mail
	$smtp->quit;                          # Close the SMTP connection

	return 1;
}

# Mount archive location
# OUTPUT: 0/1 .. failure/success
sub mountArchiveLocation {
	my %config = &getConfig();
	if (!$config{archive_location_mount_cmd}) {
		return 0;
	}

	my $cmd = $config{archive_location_mount_cmd};
	&debug("Mounting archive location: $cmd");
	my $result = system($cmd);
	&debug("Result: $result",10);
	return 1;
}

# Unmount archive location
# OUTPUT: 0/1 .. failure/success
sub umountArchiveLocation {
	my %config = &getConfig();
	if (!$config{archive_location_umount_cmd}) {
		return 0;
	}

	my $cmd = $config{archive_location_umount_cmd};
	&debug("Unmounting archive location: $cmd");
	my $result = system($cmd);
	&debug("Result: $result",10);
	return 1;
}

# vRanger backup all VM's from configuration
# OUTPUT: 0/1 .. failure/success
sub backupVMs {
	my %config = &getConfig();

	# go through all VM machines in configuration in "backup_order" order
        my @vm = split(/ /,$config{backup_order});
	my $vmname;
	foreach $vmname (@vm) {
		my $message;
		my $virtualcenter_vm;
		my $drives;
		my $prescript;
		my $postscript;

		$message = "Backup VM $vmname:";
		if ($config{VM}{$vmname}{virtualcenter_vm}) {
			$virtualcenter_vm =  $config{VM}{$vmname}{virtualcenter_vm};
			$message .= " Virtualcenter VM id: " . $virtualcenter_vm;
		} else {
			&debug("Cannot $message. No virtualcenter_vm in configuration.");
			next;
		}	
		if ($config{VM}{$vmname}{drives}) {
			$drives =  $config{VM}{$vmname}{drives};
			$message .= " VM drives for backup: " . $drives;
		} else {
			&debug("Cannot $message. No drives in configuration.");
			next;
		}

		&debug($message, 1);

		# run backup pre-script
		if ($config{VM}{$vmname}{prescript}) {
			$prescript = $config{VM}{$vmname}{prescript};
			&debug("Run pre-script: $prescript");
			&debug("  Command: $prescript");
    			my $error_level = system $prescript;
			&debug("  ERROR_LEVEL = $error_level");
		} else {
			&debug("No pre-script defined");
		}

		# backup VM
		my $result = &backupVM (
			vmname => $vmname,
			virtualcenter_vm => $virtualcenter_vm,
			drives => $drives,
		);

		## vRanger nevraci uspech/neuspech, takze to nemuzeme zalogovat
		#if ($result == 1) {
		#	&debug("VM $vmname backup successfully");
		#} else {
		#	&debug("Backup of VM $vmname failed");
		#}

		# run backup post-script
		if ($config{VM}{$vmname}{postscript}) {
			$postscript = $config{VM}{$vmname}{postscript};
			&debug("Run post-script: $postscript");
			&debug("  Command: $postscript");
    			my $error_level = system $postscript;
			&debug("  ERROR_LEVEL = $error_level");
		} else {
			&debug("No post-script defined");
		}

	}

	return 1;
}

# vRanger check today's backup of all VM's from configuration
# parameter what_check defines what files we want to check
# INPUT: params = { 
# 		what_check => "all_backups" | "backups_for_restore", 
# 		}
# OUTPUT: 0/1 .. failure/success
sub checkTodayBackup {
	my %params = @_;
	my %config = &getConfig();
	
	my $result = 1; #success
	my $what_check = $params{what_check};

	if (($what_check ne "all_backups") && ($what_check ne "backups_for_restore")) {
		&debug("Parameter what_check is not properly defined so there is nothing to check.");
		&debug("Parameter can have value 'all_backups' or 'backups_for_restore'.");
		die "unexpected parameter";
	}

	# go through all VM machines in configuration in "backup_order" or "restore_order" order
	#
       	my @vm = ();
	if ($what_check eq "all_backups") {
        	@vm = split(/ /,$config{backup_order});
	} else {
        	@vm = split(/ /,$config{restore_order});
	}
	my $vmname;
	my $vm_result;
	foreach $vmname (@vm) {
		my $message;

		# check backup of VM
		$message = "Check today's backup of VM $vmname: ";
		$vm_result = &checkTodayBackupVM (
			vmname => $vmname,
		);

		if ($vm_result == 1) {
			$message .= "success";
		} else {
			$message .= "fail";
			$result = 0; # fail
		}

		&debug($message, 1);
	}

	return $result;
}

# vRanger restore all VM's from configuration
# OUTPUT: 0/1 .. failure/success
sub restoreVMs {
	my %config = &getConfig();

	# Check if all images for restore are ready
	if (!&checkTodayBackup(what_check=>"backups_for_restore")) {
		&debug("Some today's backup are not ready for restore.");
		&debug("Restore task has been canceled.");
		return 0;
	}

	# go through all VM machines in configuration in "restore_order" order
        my @vm = split(/ /,$config{restore_order});
	my $vmname;
	foreach $vmname (@vm) {
		my $message;
		my $internalname;
		my $destserver;
		my $destdatastore;
		my $networkname;

		$message = "Restore VM $vmname:";
		if ($config{VM}{$vmname}{internalname}) {
			$internalname =  $config{VM}{$vmname}{internalname};
			$message .= " Internal name: " . $internalname;
		} else {
			&debug("Cannot $message. No internalname in configuration.");
			next;
		}
		if ($config{VM}{$vmname}{destserver}) {
			$destserver =  $config{VM}{$vmname}{destserver};
			$message .= " Destination ESX server: " . $destserver;
		} else {
			&debug("Cannot $message. No destserver in configuration.");
			next;
		}
		if ($config{VM}{$vmname}{destdatastore}) {
			$destdatastore =  $config{VM}{$vmname}{destdatastore};
			$message .= " Destination datastore: " . $destdatastore;
		} else {
			&debug("Cannot $message. No destdatastore in configuration.");
			next;
		}
		if ($config{VM}{$vmname}{networkname}) {
			$networkname =  $config{VM}{$vmname}{networkname};
			$message .= " Network name: " . $networkname;
		} else {
			&debug("Cannot $message. No networkname in configuration.");
			next;
		}

		&debug($message, 1);

		# restore VM
		my $result = &restoreVM (
			vmname => $vmname,
			internalname => $internalname,
			destserver => $destserver,
			destdatastore => $destdatastore,
			networkname => $networkname,
		);

		## vRanger nevraci uspech/neuspech, takze to nemuzeme zalogovat
		#if ($result == 1) {
		#	&debug("VM $vmname restored successfully");
		#} else {
		#	&debug("Restore of VM $vmname failed");
		#}

	}

	return 1;
}

# vRanger backup one virtual machine to image archive
# INPUT: params = { 
# 		vmname => "LL-DB", 
# 		virtualcenter_vm => "vc2://VirtualMachine=vm-732", 
# 		drives => "1,2", 
# 		}
# OUTPUT: 0/1 .. failure/success
sub backupVM {
	my %params = @_;
	my %config = &getConfig();

	my $today = &getCurrentDate(format=>"YYYY.MM.DD");

	my $cmd = "";
	$cmd = $config{vranger_exe};
	$cmd.= " -virtualcenter " . $params{virtualcenter_vm};
	$cmd.= " -copylocal " . $config{backup_location};
	$cmd.= " -drives:" . $params{drives};
        $cmd.= " -zipname " . $today . "_" . $params{vmname};
	$cmd.= " -vmnotes -noquiesce";

	&debug("vRanger backup command: " . $cmd );
	
	my $result = system "$cmd";

	return $result;
}

# check backup status vRanger backup of virtual machine in image archive
# INPUT: params = { 
# 		vmname => "LL-DB", 
# 		destserver => "esx1-bs.home.uw.cz", 
# 		destvmfs => "\"VM's Configuration,Datastore2;LL-DB.vmdk,Datastore2;\"",
# 		networkname => "ethernet0,VI_STANDBY",
# 		}
# OUTPUT: 0/1 .. failure/success
sub checkTodayBackupVM {
	my %params = @_;
	my %config = &getConfig();

	my $result = 0; #fail
	my $today = &getCurrentDate(format=>"YYYY.MM.DD");

	#open backup info file

	my $filename = $config{backup_location} . "\\" . $today . "_" . $params{vmname} . ".tvzc.info";
	&debug("Open info file: " . $filename,10 );
	if (open INFO, "< $filename") {
		my $info;
		while (<INFO>) {
			chomp($_);
			$info .= $_;
		}

		# Check if exist <Error>Success</Error>
		if ($info =~ /<Error>Success<\/Error>/) {
			&debug("Status file contains <Error>Success</Error>.",10);
			$result = 1;
		} else {
			&debug("Status file doesn't contain <Error>Success</Error>.",10);
			$result = 0;
		}
	} else {
		&debug("Open file doesn't exist. Backup failed.",10);
		$result = 0;
	}

	return $result;
}


# vRanger restore one virtual machine from image archive
# INPUT: params = { 
# 		vmname => "LL-DB", 
# 		internalname => "LL-Database", 
# 		destserver => "esx1-bs.home.uw.cz", 
# 		destdatastore => "Datastore2",
# 		networkname => "ethernet0,VI_STANDBY",
# 		}
# OUTPUT: 0/1 .. failure/success
sub restoreVM {
	my %params = @_;
	my %config = &getConfig();

	my $today = &getCurrentDate(format=>"YYYY.MM.DD");

	#"VM's Configuration,Datastore2;LL-DB.vmdk,Datastore2;"
	my $destvmfs = "VM's Configuration,$params{destdatastore};$params{internalname}.vmdk,$params{destdatastore};";

	my $cmd = "";
	$cmd = $config{vranger_exe};
	$cmd.= " -restore ";
	$cmd.= " -local " . $config{backup_location} . "\\" . $today . "_" . $params{vmname} . ".tvzc.info";
	$cmd.= " -destserver " . $params{destserver};
        $cmd.= " -destvmfs \"" . $destvmfs . "\"";
	$cmd.= " -networkname " . $params{networkname};
	$cmd.= " -forcepoweroff -restoreconfig -registervm  -forceoverwrite -unattended ";

	&debug("vRanger command: " . $cmd );
	
	my $result = system "$cmd";

	return $result;
}

# deleteold
# INPUT: params = { archive_location => "R:\archive", olderthan => 10 }
# OUTPUT: 0/1 - fail/success
sub deleteold {
	my %params = @_;
	my %config = &getConfig();
	my $filename;
        my $full_filename;

	if (!$params{archive_location}) {
		$params{archive_location} = $config{archive_location};
	}

	if (!$params{archive_location}) {
		&debug("Cannot delete old images. Archive location is not defined.");
		return 0;
	}

	if (!$params{olderthan}) {
		$params{olderthan} = 7;
	}

	# try open directory or return fail
	if (not(opendir DIR, $params{archive_location})) { 
		&debug("Cannot open directory " . $params{archive_location}); 
		return 0;
	} 

	&debug("Directory " . $params{archive_location} . " has been opened");
	while ($filename = readdir DIR) {
		$full_filename = $params{archive_location} . '\\' . $filename;
		# open file
		&debug("Open file: ". $full_filename, 10 );
		if ( -f $full_filename ) {
			my $file_age = -M $full_filename;
			&debug("File name: ". $full_filename . " age: " . $file_age, 10);
			if ( $file_age >= $params{olderthan} ) {
				&debug("Delete file: " . $full_filename);
				unlink $full_filename;
			}
		}
	}

	return 1;
}

