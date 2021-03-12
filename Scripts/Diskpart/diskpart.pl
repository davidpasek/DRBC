use strict;
use warnings;
use IPC::Open2;
use Data::Dumper;
use Getopt::Std;

print "DISKPART Perl Wrapper\n";
&debug_start();

# -m stands for mode (check_volumes_letters, check_rw_all_volumes)
# -d stands for disks
# diskpart.pl -d DEF (check and set r/w for disks D: E: F:)
my %options=();
getopts("m:d:",\%options);

unless ($options{m} || $options{d}) {
	print "diskpart.pl\n";
	print "Options:\n";
	print "  -m [operation mode]\n";
        print "      Operation modes:\n";
        print "        check_volumes_letters\n";
        print "        check_rw_all_volumes\n";
	print "  -d [string of disk drive letters]\n";
	print "\n";
	print "Example:\n";
	print "  diskpart.pl -m check_volumes_letters -d DEFGH  ... means test and repair disks D: E: F: G: H:\n";
	print "  diskpart.pl -m check_rw_all_volumes -d DEFGH  ... means set disks D: E: F: G: H: to R/W mode\n";
	&debug("No correct options has been entered");
	&debug_end();
	die;	
}

my $mode=lc($options{m});
my $disks=uc($options{d});

my $result = 1;

if ($mode eq "check_volumes_letters") {
	# Check if volumes are mounted to right letters
	$result = &checkVolumesLetters("disks" => $disks);
}

if ($mode eq "check_rw_all_volumes") {
	# Check if volumes are mounted to right letters
	$result = &checkRWAllVolumes("disks" => $disks);
}

my $ERROR_LEVEL = 0;
if ($result != 1) {
	$ERROR_LEVEL = 1;
}

&debug("ERROR_LEVEL: $ERROR_LEVEL");
&debug_end();

exit $ERROR_LEVEL;

##################################################

# &checkRWAllVolumes(disks => "DEF")
sub checkRWAllVolumes {
	my %params = @_;

	# Check if disks are R/W
	if ( &disksAreRW("disks" => $params{disks}) ) {
		&debug("Disks $disks are RW.");
		return 1;
	}

	my %config = &getConfig();

	# Set RW for all volumes
	&setRWAllVolumes();

	#REBOOT
	&reboot();

	return 0;
}

# Check order of volume letters and change it to right order
# &checkVolumesLetters(disks => "DEF")
sub checkVolumesLetters {
	my %params = @_;

	&debug("Geting all disks volumes ...", 1);
	my @volume_a = &diskpart_getAllVolumes();
	my %remap_drive_letter = ();
	my %remap_drive_volumename = ();
	my @diskpart_volume_label_letters = (); # for test if all volumes (letters) are visible by diskpart
		
	&debug("Checking disks volumes if it's right mounted to drive letters ...", 1);

	# Go across all volumes
	for (@volume_a) {
		my %volume = %$_; # Volume entity (hash)

		# get last letter from label
		my $right_letter = substr( $volume{volume_label}, length($volume{volume_label}) - 1, 1 );
		# store letter of visible volume
		push @diskpart_volume_label_letters, uc($right_letter);

		&debug("Volume Label:" . $volume{volume_label}, 10);
		&debug("Right letter:" . $right_letter, 10);
		&debug("Volume Letter:" . $volume{volume_letter}, 10);
		
		if ( ($volume{volume_letter} ne "") && ($right_letter ne $volume{volume_letter}) ) {
			&debug("Remap drive:" . $volume{volume_letter}, 10);
			$remap_drive_letter{$volume{volume_letter}}=$right_letter;
			$remap_drive_volumename{$volume{volume_letter}}=&getDriveVolumeName("drive_letter" =>$volume{volume_letter});
		}
	}

	my @disks; # array of reqired disks letters

	# start - test if all volumes (letters) are visible by diskpart
	&debug("Test if all volumes (letters) are visible by diskpart");
	my $label_letters = join ("", sort @diskpart_volume_label_letters);
	&debug("Label letters: $label_letters");
	@disks = split(//,$params{disks});
	foreach (@disks) {
		my $disk = uc($_);
		if ( not ($label_letters =~ $disk) ) { 
			&debug("Diskpart cannot see all required volumes. Required: " . $disk . " Can see: $label_letters");
			#REBOOT
			&reboot();
			return 0;
		}
	}
	# end - test if all volumes (letters) are visible by diskpart
	
	@disks = split(//,$params{disks});
	foreach (@disks) {
		my $disk = $_;
		if ($remap_drive_letter{$disk}) {
			&debug("Remap disk letter $disk to disk letter " . $remap_drive_letter{$disk} );
			&debug("Volume name " . $remap_drive_volumename{$disk} );
			&debug("Unmount " . $disk );
			&unmountDrive("drive_letter" => $disk);
		}

	}	

	foreach (@disks) {
		my $disk = $_;
		if ($remap_drive_letter{$disk}) {
			&debug("Remap disk letter $disk to disk letter " . $remap_drive_letter{$disk} );
			&debug("Volume name " . $remap_drive_volumename{$disk} );
			&debug("Mount " . $remap_drive_letter{$disk} );
			&mountDrive("drive_letter" => $remap_drive_letter{$disk}, "volume_name" => $remap_drive_volumename{$disk});
		}

	}	

	return 1;
}

# Test if disks are Read/Write
# &diskAreRW(disks => "DEF")
sub disksAreRW {
	my %params = @_;

	my @disks = split(//,$params{disks});
	foreach (@disks) {
		my $disk = $_;
		my $test_filename = $disk . ':\diskpart-testfile.txt';
		&debug("Test RW of disk $disk - write to file $test_filename");

		if (open TST, " > $test_filename ") {
			print TST "Write test into file $test_filename\n";
			close TST;
		} else {
			&debug("Cannot write into disk $disk");
			return 0;
		}
	}
	
	return 1;
}

# Load Today Reboot Counter
# $todays_reboots = &loadTodayRebootCounter(); # it returns number of today reboots 
sub loadTodayRebootCounter {
	my %config = &getConfig();

	my $current_date = `date /T`; 
	chomp($current_date);
	my ($day,$mm,$dd,$yyyy) = split(/[\/,\s]/,$current_date);
	my $today = "$yyyy$mm$dd";

	my $filename = $config{reboot_counter};
	my $line;
	if (open CNT, "$filename") {
		$line = <CNT>;
		close CNT;
	} else {
		&debug("Cannot read $filename");
		return 0;
	}
	
	chomp($line);
	&debug("Reboot counter: $line",10);
        my ($line_today,$line_counter)=split(/;/,$line);

	if ($line_today eq $today) {
		&debug("Today reboot counter: $line_counter",10);
		return $line_counter;
	} else {
		&debug("Today reboot counter: 0",10);
		return 0;
	}
}

# Save Today Reboot Counter
# &saveTodayRebootCounter(today_reboot_counter => $today_reboot_counter);
sub saveTodayRebootCounter {
	my %params = @_;
	my %config = &getConfig();

	my $current_date = `date /T`; 
	chomp($current_date);
	my ($day,$mm,$dd,$yyyy) = split(/[\/,\s]/,$current_date);
	my $today = "$yyyy$mm$dd";

	my $filename = $config{reboot_counter};
	my $today_reboot_counter = $params{today_reboot_counter};
	if (open CNT, " > $filename") {
		print CNT "$today;$today_reboot_counter\n";
		close CNT;
	} else {
		&debug("Cannot write into $filename");
		return 0;
	}
	
	return 1;
}

# Get Drive Volume Name
# &getDriveVolumeName("drive_letter" =>$volume{volume_letter});
sub getDriveVolumeName {
	my %params = @_;
	my %config = &getConfig();

	my $cmd = "$config{mountvol_command} $params{drive_letter}: /L";
	&debug("getDriveVolumeName command:" . $cmd, 10);
	my $volume_name = `$cmd`;
	&debug("getDriveVolumeName result:" . $volume_name, 10);
	chomp($volume_name);

	return $volume_name;
}

# unmount Drive 
# &unmountDrive("drive_letter" =>$volume{volume_letter});
sub unmountDrive {
	my %params = @_;
	my %config = &getConfig();

	my $cmd = "$config{mountvol_command} $params{drive_letter}: /D";
	&debug("Unmount drive command:" . $cmd, 10);
	`$cmd`;

	return 1;
}

# mount Drive letter with volume name
# &mountDrive("drive_letter" => $remap_drive_letter{$disk}, "volume_name" => $remap_drive_volumename{$disk});
sub mountDrive {
	my %params = @_;
	my %config = &getConfig();

	my $cmd = "$config{mountvol_command} $params{drive_letter}: $params{volume_name}";
	&debug("Mount drive command:" . $cmd, 10);
	`$cmd`;

	return 1;
}


# List all volumes 
sub listAllVolumes {

	my @volume_a = &diskpart_getAllVolumes();

	# Go across all volumes
	for (@volume_a) {
		# START - DECLARATIONS FOR THIS BLOCK
		my %volume = %$_;			# Volume entity (hash)
		my %params;				# Parameters for functions (hash) 
		# END   - DECLARATIONS FOR THIS BLOCK

		&debug("---------------------------------------", 10);
		&debug("Volume Number:" . $volume{volume_number}, 10);
		&debug("Volume Label:" . $volume{volume_label}, 10);
		&debug("Volume Letter:" . $volume{volume_letter}, 10);

	}

	return 1;
}

# Set all volumes to R/W, no hidden mode, no shadowcopy, defaultdriveletter
sub setRWAllVolumes {

	my @volume_a = &diskpart_getAllVolumes();

	# Go across all volumes
	for (@volume_a) {
		# START - DECLARATIONS FOR THIS BLOCK
		my %volume = %$_;			# Volume entity (hash)
		my %params;				# Parameters for functions (hash) 
		# END   - DECLARATIONS FOR THIS BLOCK

		&debug("Setting volume bellow to READ/WRITE mode ...");
		&debug("Volume Number:" . $volume{volume_number});
		&debug("Volume Label:" . $volume{volume_label});
		&debug("Volume Letter:" . $volume{volume_letter});

		# SET ALL VOLUME ATTRIBUTES TO NO 
		%params = ( 
			volume_number => $volume{volume_number},
			attr_hidden => 0,
			attr_readonly => 0,
			attr_nodefaultdriveletter => 0,
			attr_shadowcopy => 0,
		);
		&diskpart_setVolumeAttributes(%params);
		sleep(5); # wait 5 seconds
	}

	return 1;
}

# Diskpart set volume attributes
# INPUT hash: 
#        {
#         volume_number=>2, 
#         attr_hidden=>0|1, 
#         attr_readonly=>0|1, 
#         attr_nodefaultdriveletter=>0|1, 
#         attr_shadowcopy=>0|1,
#         assign_letter=> undef | [A..Z],
#        }
# OUTPUT: return 0 - fail, 1 - success
sub diskpart_setVolumeAttributes {
	my %params = @_;
	my $volume_number = $params{volume_number};
	my $attr_hidden = $params{attr_hidden};
	my $attr_readonly = $params{attr_readonly};
	my $attr_nodefaultdriveletter = $params{attr_nodefaultdriveletter};
	my $attr_shadowcopy = $params{attr_shadowcopy};
	my $assign_letter = $params{assign_letter};
	my %config=&getConfig();
	my $cmd;

	local (*READ, *WRITE);
	my $pid = open2(\*READ, \*WRITE, $config{diskpart_command} ); 
	&debug("Run command:" . $config{diskpart_command},10);

	# Issue commands
	$cmd = "select volume $volume_number\n";
	print WRITE $cmd;
	&debug($cmd,10);
	
	if ($attr_hidden) {
		$cmd = "attributes volume set hidden\n";
		print WRITE $cmd;
		&debug($cmd,10);
	} else {
		$cmd = "attributes volume clear hidden\n";
		print WRITE $cmd;
		&debug($cmd,10);
	}
	if ($attr_readonly) {
		$cmd = "attributes volume set readonly\n";
		print WRITE $cmd;
		&debug($cmd,10);
	} else {
		$cmd = "attributes volume clear readonly\n";
		print WRITE $cmd;
		&debug($cmd,10);
	}
	if ($attr_nodefaultdriveletter) {
		$cmd = "attributes volume set nodefaultdriveletter\n";
		print WRITE $cmd;
		&debug($cmd,10);
	} else {
		$cmd = "attributes volume clear nodefaultdriveletter\n";
		print WRITE $cmd;
		&debug($cmd,10);
	}
	if ($attr_shadowcopy) {
		$cmd = "attributes volume set shadowcopy\n";
		print WRITE $cmd;
		&debug($cmd,10);
	} else {
		$cmd = "attributes volume clear shadowcopy\n";
		print WRITE $cmd;
		&debug($cmd,10);
	}
	if ($assign_letter) {
		$cmd = "assign letter=\"$assign_letter\"\n";
		print WRITE $cmd;
		&debug($cmd,10);
	} 
	$cmd = "exit\n";
	print WRITE $cmd;
	&debug($cmd,10);

	close(WRITE);

	# Read output
	my @output = <READ>;
	my $output = join ('', @output);
	&debug($output,10);
	if ( $output =~ /There is no volume selected./ ) {
		# FAIL
		return 0;
	}
	# SUCCESS
	return 1;
}

# Diskpart getAll Volumes
# INPUT: no parameter
# OUTPUT: array of hashes
#    [1]{volume_number} = 1
#    [1]{volume_letter} = "D"
#    [1]{volume_label} = "FS_D"
#    [2]{volume_number} = 2
#    [2]{volume_letter} = "D"
#    [2]{volume_label} = "FS_D"
sub diskpart_getAllVolumes {
	local (*READ, *WRITE);
	my @volume_a = ();
	my %volume_h = ();
	my %config=&getConfig();
	my $cmd;
	my $pid = open2(\*READ, \*WRITE, $config{diskpart_command} ); 
	&debug("Run command:" . $config{diskpart_command},10);

	# Issue commands
	$cmd = "list volume\n";
	print WRITE $cmd;
	&debug($cmd,10);
	
	$cmd = "exit\n";
	print WRITE $cmd;
	&debug($cmd,10);

	close(WRITE);

	# Read output
	my @output = <READ>;
	my $output = join ('', @output);
	&debug($output,10);

	foreach my $line (@output) {
		chomp($line);
		VOLUME: if ($line =~ /Volume/) {
			my $vol_number = substr($line,9,3);
			my $i = $vol_number;
			if ($vol_number !~ /\d+/) {
				# it's not a volume number
				# it is probably ### (volume number title)
				next;
		        } 
			$volume_a[$i]{volume_number} = $vol_number;
			my $vol_letter = substr($line,14,3);
		        $vol_letter =~ s/\s//g;
			$volume_a[$i]{volume_letter} = $vol_letter;
			my $vol_label = substr($line,19,11);
		        $vol_label =~ s/\s//g;
			$volume_a[$i]{volume_label} = $vol_label;
			my $vol_fs = substr($line,32,5);
		        $vol_fs =~ s/\s//g;
			$volume_a[$i]{volume_fs} = $vol_fs;
			my $vol_type = substr($line,39,10);
		        $vol_type =~ s/\s//g;
			$volume_a[$i]{volume_type} = $vol_type;
			my $vol_size = substr($line,51,7);
		        $vol_size =~ s/\s//g;
			$volume_a[$i]{volume_size} = $vol_size;
			my $vol_status = substr($line,60,9);
		        $vol_status =~ s/\s//g;
			$volume_a[$i]{volume_status} = $vol_status;
			my $vol_info = substr($line,71,8);
		        $vol_info =~ s/\s//g;
			$volume_a[$i]{volume_info} = $vol_info;

			DEBUG: {
				&debug ("$line",10);
				&debug ("Volume number: " . $volume_a[$i]{volume_number},10); 
				&debug ("Volume letter:$volume_a[$i]{volume_letter}",10); 
				&debug ("Volume label:$volume_a[$i]{volume_label}",10); 
				&debug ("Volume file system:$volume_a[$i]{volume_fs}",10); 
				&debug ("Volume type:$volume_a[$i]{volume_type}",10); 
				&debug ("Volume size:$volume_a[$i]{volume_size}",10); 
				&debug ("Volume status:$volume_a[$i]{volume_status}",10); 
				&debug ("Volume info:$volume_a[$i]{volume_info}",10);
			}	
		}
	}

	return @volume_a;
} # end diskpart_getAllVolumes

# Mail Notification
# INPUT: params = { 
# 		subject => "DRBC/DISKPART.PL", 
# 		message => "Maximum restart treshold has been achieved.",
# 		}
# OUTPUT: 0/1 .. failure/success
sub mailNotify {
	my %params = @_;
	my %config = &getConfig();

	&debug("Sending mail notification ...");

	my $relay=$config{mail_smtp_server};
	my $to=$config{mail_to};
	my $from=$config{mail_from};
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

# Reboot
sub reboot {
	my %config = &getConfig();

	# Handle Reboot Counter - begin
	my $today_reboot_counter = &loadTodayRebootCounter();
	$today_reboot_counter = $today_reboot_counter + 1;
	&saveTodayRebootCounter(today_reboot_counter => $today_reboot_counter);
	# Handle Reboot Counter - end

	if ($today_reboot_counter<$config{max_reboots}) {
		# REBOOT SERVER
		my $reboot_command = $config{reboot_command};
		&debug("Rebooting server ...");
		&debug("   command: $reboot_command");
		my $reboot_result = `$reboot_command`;
		&debug("Reboot result: $reboot_result");
		&debug("Sleep 30 seconds ...");
		sleep(30);
		&debug_end();	
		return 1;
	}

	&debug("Cannot reboot server because maximum of reboots has been achieved.");
	# notify admin by email
	&mailNotify(subject=> "DRBC/DISKPART.PL", message=>"Cannot reboot server because maximum of reboots has been achieved.");
	&debug_end();	

	return 1;
}

# Configuration hash
sub getConfig {
	my %CONFIG = ();
	#DEBUG 1 = yes, 0 = no?
	#$CONFIG{debug} = 1;
	$CONFIG{debug} = 0;
	$CONFIG{debug} = 1;
	$CONFIG{debug_output} = 'c:\drbc\log\diskpart.pl.log';

	$CONFIG{mail_smtp_server}="pluto.home.uw.cz";
	$CONFIG{mail_to}="it\@home.uw.cz";
	$CONFIG{mail_from}="it\@home.uw.cz";

	$CONFIG{diskpart_command}='c:\windows\system32\diskpart.exe';
	$CONFIG{mountvol_command}='c:\windows\system32\mountvol.exe';
	$CONFIG{reboot_command}='c:\windows\system32\shutdown.exe /r /f /t 0';
	$CONFIG{reboot_counter} = 'c:\drbc\log\reboot_counter.log';
	$CONFIG{max_reboots} = 10;

	return %CONFIG;
}

# Debug start
#   print debug header (date & time)
sub debug_start {
	my %config=&getConfig();
	if (!$config{debug}) { return 0; }

	my $current_date = &getCurrentDate(format=>"YYYY.MM.DD");
	my $current_time = &getCurrentTime();
	&debug("*******************************************************************************");
	&debug("Starting Perl Wrapper at " . $current_date . " " . $current_time);

	my $argnum;
	my $is_password = 0;
	my $cmd_args = "";
	foreach $argnum (0 .. $#ARGV) {
		if ($is_password) {
   			$cmd_args .= "***** ";
			$is_password = 0;
			next;
		}

   		$cmd_args .= $ARGV[$argnum] . " ";

		if ($ARGV[$argnum] eq "--password") {
			$is_password = 1;
		}
	}
	&debug("Command line arguments: " . $cmd_args);	
}

# Debug end
#   print debug footer (date & time)
sub debug_end {
	my %config=&getConfig();
	if (!$config{debug}) { return 0; }

	my $current_date = &getCurrentDate(format=>"YYYY.MM.DD");
	my $current_time = &getCurrentTime();
	&debug("Ending Perl Wrapper at " . $current_date . " " . $current_time);
}

# Debug line
sub debug {
       	my ($msg, $level, @rest) = @_;
	if (!$level) {$level=1}; # set debug level 1 if level is not explicitely defined 

	my %config=&getConfig();

	if ( $config{debug} < $level ) {return;} # no debug when config debug level is lower then current debug message

	chomp($msg);

	# write debug message to log file
	if ( $config{debug_output} && ($config{debug_output} ne "") ) {
		if (open DBG, " >> $config{debug_output} ") {
			print DBG "$msg\n";
		} else {
			print "!!! CANNOT WRITE TO DEBUG LOG !!! - check debug_output variables in configuration.\n";
		}
	} 

	# write debug message to standard output
	print "$msg\n";

	return 1;
}

# INPUT: params = { 
# 		format => "YYYY.MM.DD" or "DD.MM.YYYY"
# 		}
#
# getCurrentDate(format=>"YYYY.MM.DD");
# OUTPUT: 0/1 .. failure/success
sub getCurrentDate {
	my %params = @_;

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);
	$year += 1900;
	$mon += 1;

	my $str;
	if ($params{format} eq "YYYY.MM.DD") {
		$str = "$year.$mon.$mday";
	}
	if ($params{format} eq "DD.MM.YYYY") {
		$str = "$mday.$mon.$year";
	}

	return $str;
}

sub getCurrentTime {
	my %params = @_;

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);
	my $str;
	$str = "$hour:$min:$sec";

	return $str;
}
