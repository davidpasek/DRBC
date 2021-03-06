use strict;
use warnings;
use IPC::Open2;
use Data::Dumper;
use Getopt::Std;
use Net::Ping;

print "DRBC TEST Framework\n";
print "ping_test\n";
&debug_start();

my %options=();
getopts("h:t:",\%options);

#my %config = &getConfig();

my $HOST;
my $TIMEOUT;

# GET PARAMETER "HOST"
if ( $options{h} ) {
	$HOST = $options{h};
}

# GET PARAMETER "TIMEOUT"
if ( $options{t} ) {
	$TIMEOUT = $options{t};
} else {
	$TIMEOUT = 600;
}

if (!$HOST) {
	# show HELP SECTION
	print "Usage:\n";
	print "ping_test.pl\n";
	print "Test if ICMP echo is responding on particular host\n";
	print "Options:\n";
	print "  -h host name or IP address\n";
	print "  -t timeout in seconds\n";
	exit 1;
	&debug_end();
}	

my $result = 0; # 0 - fail, 1 - ok
my $t = 0;
my $error_level = 0;

while (!$result and $t<$TIMEOUT) {
	&debug("PINGing $HOST ...");

    	my $p = Net::Ping->new('icmp');
    	if ($p->ping($HOST)) {
		$result = 1;
	}
    	$p->close();
	
	if (!$result) {
		&debug("Sleep 5 seconds before next try ...");
		sleep(5);
		$t=$t+5;
	}

}

if (!$result) {
	&debug("Service is not running.");
	$error_level = 1;
} else {
	&debug("Service is ok.");
	$error_level = 0;
}

&debug_end();
exit $error_level;

# Configuration hash
sub getConfig {
	my %CONFIG = ();
	#DEBUG 1 = yes, 0 = no?
	#$CONFIG{debug} = 1;
	$CONFIG{debug} = 0;
	$CONFIG{debug} = 1;
	$CONFIG{debug_output} = 'c:\drbc\log\net_test.pl.log';
	return %CONFIG;
}


# Debug start
#   print debug header (date & time)
sub debug_start {
	my %config=&getConfig();
	if (!$config{debug}) { return 0; }

	my $current_date = `date /T`; 
	my $current_time = `time /T`;
	chomp($current_date);
	chomp($current_time);
	&debug("*******************************************************************************");
	&debug("Starting Perl Wrapper at " . $current_date . " " . $current_time);
}

# Debug end
#   print debug footer (date & time)
sub debug_end {
	my %config=&getConfig();
	if (!$config{debug}) { return 0; }

	my $current_date = `date /T`; 
	my $current_time = `time /T`;
	chomp($current_date);
	chomp($current_time);
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
