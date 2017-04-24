#!/usr/bin/env perl
#

use warnings;
use strict;
use Data::Dumper;
use Digest::MD5;

my %addresses=();

=head1 Data Format

  0 First Name
  1 Last Name
  2 Street Address
  3 City
  4 State
  5 ZipCode
  6 Phone 
  7 Street Num 
  8 Street Locater ( NW, SW, etc)
  9 Street Name
 10 Street Designator (ST, CT, DR, Drive, etc)


=cut

use constant FNAME => 0;
use constant LNAME => 1;
use constant STREETADDRESS => 2;
use constant CITY => 3;
use constant STATE => 4;
use constant ZIPCODE => 5;
use constant PHONE => 6;
use constant STREETNUM => 7;
use constant STREETLOC => 8; # loc = locater = NW, SW, ...
use constant STREETNAME => 9; 
use constant STREETDESG => 10;  


my $noAddress = 0;
my $dupAddress = 0;

# detect duplicate records
my %addressHash=();

while (<>) {

	chomp;
	# remove leading/trailing spaces
	#s/\s+,\s+/,/g;

	my @data = split(/,/);
	my $md5 =  Digest::MD5->new;
	$md5->add(@data);
	my $digest = $md5->hexdigest;

	#print "Digest: $digest\n";

	if ( exists $addressHash{$digest} ) {
		$dupAddress++;
		next;
	} else {
		$addressHash{$digest} = 'Original';
	}

	#print Dumper(\@data);
	
	unless ($data[STREETADDRESS]) {
		#print "Skipping - no address\n"; 
		$noAddress++;
		next;
	}

	# get names and phones
	push @{$addresses{$data[STREETADDRESS]}->{'NAMES'}{$data[LNAME]}}, [ $data[FNAME], $data[PHONE]];

	# the following fields will be useful for sorting
	$addresses{$data[STREETADDRESS]}->{'CITY'} = $data[CITY];
	$addresses{$data[STREETADDRESS]}->{'STATE'} = $data[STATE];
	$addresses{$data[STREETADDRESS]}->{'ZIPCODE'} = $data[ZIPCODE];
	$addresses{$data[STREETADDRESS]}->{'STREETNUM'} = $data[STREETNUM];
	$addresses{$data[STREETADDRESS]}->{'STREETNAME'} = qq{$data[STREETLOC] $data[STREETNAME] $data[STREETDESG]};



}


print 'Addresses: ' , Dumper(\%addresses);

warn "$noAddress records skipped due to no address\n";
warn "$dupAddress records skipped due as duplicates\n";



