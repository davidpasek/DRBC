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

	my $current_date = &getCurrentDate(format=>"YYYY.MM.DD");
	my $current_time = &getCurrentTime();

	my %config=&getConfig();

	if ( $config{debug} < $level ) {return;} # no debug when config debug level is lower then current debug message

        my $script_name = $config{script_name};
	if (!defined($script_name)) {
		$script_name="[\$script_name]";
	}
	chomp($msg);

	# write debug message to log file
	if ( $config{debug_output} && ($config{debug_output} ne "") ) {
		if (open DBG, " >> $config{debug_output} ") {
			print DBG "$current_date $current_time\t$script_name: $msg\n";
		} else {
			print "!!! CANNOT WRITE TO DEBUG LOG !!! - check debug_output variables in configuration.\n";
		}
	} 

	# write debug message to standard output
	print "$msg\n";

	return 1;
}

1;
