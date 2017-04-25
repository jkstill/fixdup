#!/usr/bin/env perl
#

use warnings;
#use strict;
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

# in the event we want to report these later
#my %recsWithoutAddresses=();
#my %dupAddresses=();

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
warn "$dupAddress records skipped as duplicates\n";

#exit;

# now we determine how to handle the data
#

=head1 Process the Data

 - one last name with multiple first names - print all first names in the same field
   - if there are 2+ phone numbers, print first name/phone for each individual
   - reduce phone numbers to one if all the same
 - if there are 2+ last name, create separate record for each last name
   - there may be multiple first names for a last name - treat the same as previously

=cut

my $cleanData ;

my $delimiter=',';

foreach my $address (keys %addresses) {
	print "### Working on $address\n";

	# make a copy of the current record to simplify code
	my $data = $addresses{$address};
	print 'Work Data: ' , Dumper($data);


	$cleanData->{$address}{'STREETNAME'} = $data->{'STREETNAME'};
	$cleanData->{$address}{'STREETNUM'} = $data->{'STREETNUM'};
	$cleanData->{$address}{'CITY'} = $data->{'CITY'};
	$cleanData->{$address}{'STATE'} = $data->{'STATE'};
	$cleanData->{$address}{'ZIPCODE'} = $data->{'ZIPCODE'};

	# get count of different phone numbers
	my @lastNames = keys %{$data->{'NAMES'}};
	print '@lastNames: ' , Dumper(\@lastNames), "\n";

	foreach my $lastName ( @lastNames ) {
	my %phoneHash;

		$cleanData->{$address}{'LASTNAME'} = $lastName;

		my $firstNames = $data->{'NAMES'}{$lastName};
		print "== LastName: $lastName\n";
		print "FirstNames: " , Dumper($firstNames);

		foreach my $el ( 0..$#{$firstNames} ) {
			#print "phonetest: $firstNames->[$el][1]\n";
			#print "fname: $firstNames->[$el][0]\n";
			$phoneHash{$firstNames->[$el][1]} = 'Phone';  # dummy value	
		}

		#print 'Dumper %phoneHash: ' || Dumper(\%phoneHash), "\n";
		#print 'keys %phoneHash: ' , join (' - ', keys %phoneHash), "\n";

		my @phones = keys %phoneHash;
		print 'Phone Data: ' , join (' | ' , @phones), "\n";

		my $phoneCount = $#phones;

		print "Last Names: ", join(' | ', @lastNames), "\n";

		if ($phoneCount < 0 ) {
			$cleanData->{$address}{'PHONE'}{$lastName} = 'NA';
		} elsif ($phoneCount > 0 ) {
				foreach my $el ( 0 ..$#{$firstNames}) {
					print "LastName: $lastName\n";
					$cleanData->{$address}{'PHONE'}{$lastName} .= qq{$firstNames->[$el][0] ->  $firstNames->[$el][1]  | };
				}
		} else {
			$cleanData->{$address}{'PHONE'}{$lastName} .= $phones[0];
		}

	}

}

print 'CleanData: ' . Dumper($cleanData);



























