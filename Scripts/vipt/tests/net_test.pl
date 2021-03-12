use strict;
use warnings;
use IPC::Open2;
use Data::Dumper;
use Getopt::Std;
use IO::Socket;

print "DRBC TEST Framework\n";
print "tcp_test\n";
&debug_start();

my %options=();
getopts("h:p:t:",\%options);

#my %config = &getConfig();

my $HOST;
my $PORT;
my $TIMEOUT;

# GET PARAMETER "HOST"
if ( $options{h} ) {
	$HOST = $options{h};
}

# GET PARAMETER "PORT"
if ( $options{p} ) {
	$PORT = $options{p};
}

# GET PARAMETER "TIMEOUT"
if ( $options{t} ) {
	$TIMEOUT = $options{t};
} else {
	$TIMEOUT = 600;
}

if (!$HOST || !$PORT) {
	# show HELP SECTION
	print "Usage:\n";
	print "tcp_test.pl\n";
	print "Test if TCP Socket is listening on particular host:port\n";
	print "Options:\n";
	print "  -h host name or IP address\n";
	print "  -p TCP port number\n";
	print "  -t timeout in seconds\n";
	exit 1;
	&debug_end();
}	

my $sock;
my $t = 0;
my $error_level = 0;

while (!$sock and $t<$TIMEOUT) {
	&debug("Connecting to $HOST:$PORT ...");
	# try connect
	$sock = IO::Socket::INET->new(PeerAddr => $HOST,
                                      PeerPort => $PORT,
                                      Proto    => 'tcp');
	
	if (!$sock) {
		sleep(5);
		$t=$t+5;
		&debug("Sleep 5 seconds before next try ...");
	}
}

if (!$sock) {
	&debug("Service is not running.");
	$error_level = 1;
} else {
	&debug("Service is ok.");
	close $sock;
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
