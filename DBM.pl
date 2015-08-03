#!/usr/bin/perl

use strict;
use warnings;
use Time::HiRes qw(usleep);

our $WAIT = 0;
my $waiting_time = 10; # in seconds.

my $SAVE_PATH = "$ENV{HOME}/Images/Scans/Dragon Ball Multiverse";
my $LAST = "$SAVE_PATH/.dbm_dl.last";
my $DBM_PAGES = "http://www.dragonball-multiverse.com/fr/pages/final";
my @IMAGE_EXT = qw(png jpg jpeg);
my $OPT = '--server-response --no-verbose --continue --tries=2 ';
$OPT .= "--header='User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:21.0) Gecko/20100101 Firefox/21.0 Iceweasel/21.0'";

if ( ! -d $SAVE_PATH ) {
	mkdir $SAVE_PATH or die("Problem with '$SAVE_PATH'.\n");
}

sub rompiche {
	my $t = shift;
	my $r = int( rand( $t ) );
	usleep $r;

	# Translate in seconds.
	#my $ur = int( $r/1000 );
	$WAIT += $r;

	return ( $r );
}

sub save_last {
	my $lastfile = shift;
	open(FH, ">$LAST") || print( "Unable re read '$LAST'.\n" ) ;
	print FH $lastfile;
	close(FH);
}

sub get_file {
	my ($url, $output) = @_;
	return '404' unless $url && $output;

	# Little waiting.
	rompiche( int( ($waiting_time * 80 / 100) * 1000) );

	my $ret = `wget $OPT --output-document='$output' '$url' 2>&1  || rm -f "$output"`;

	# Return status only.
	if ( $ret =~ m#HTTP/[0-9]\.[0-9] ([0-9]{3}) #i ) {
		return $1;
	}
	else {
		# No return code… WTF ?
		return '500';
	}
}

# Count 404 errors in order to
# stop downloading when done.
my $ERR_COUNT = 0;

# Current filename to download.
# Will be incremented.
my $filename;

if ( -f "$LAST" ) {
	open(FH, "<$LAST") || print( "Unable re read '$LAST'.\n" ) ;
	$filename = <FH>;
	close(FH);
} else {
	$filename = 0;
}


print "Trying : file\t\tstatus\t\tsleep (us)\n";
while ( $ERR_COUNT < 6 ) {
	# Resume 2 files ago.
	save_last( $filename - 2 );

	$filename++;

	BEXT:foreach my $ext( @IMAGE_EXT ) {
		my $file = sprintf( "%04d", $filename );
		$file .= ".$ext";

		print "\t$file\t";
		my $status = get_file( "$DBM_PAGES/$file", "$SAVE_PATH/$file" );
		print "$status\t\t";

		if ( $status =~ /200|416/ ) {
			$ERR_COUNT = 0;

			# Wait a random time, in order to
			# don't overload server, or be
			# banished
			print rompiche( $waiting_time * 1000 ),"\n";

			# File downloaded;
			# Getting next.
			last BEXT;
		}
		else {
			print "\n";
			$ERR_COUNT++;
		}
	}
}

$WAIT = int( $WAIT/1000 );
print "\n3 errors for last file :\nprobably the end of the list.\nAbording.\nTotal waiting : ~$WAIT seconds.\n\n";


__END__



#wget  --no-verbose --continue --tries=3 --header='User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:21.0) Gecko/20100101 Firefox/21.0 Iceweasel/21.0' http://www.dragonball-multiverse.com/fr/pages/final/001.png
