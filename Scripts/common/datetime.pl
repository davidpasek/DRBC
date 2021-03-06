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

1;
