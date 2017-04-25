#!/usr/bin/env perl
#

use warnings;
#use strict;
use Data::Dumper;
use Digest::MD5;

my $debug=0;

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
use constant APTNUM => 11;

# in the event we want to report these later
#my %recsWithoutAddresses=();
#my %dupAddresses=();

my $noAddress = 0;
my $dupAddress = 0;

# detect duplicate records
my %addressHash=();

while (<>) {

	my $line=$_;
	next if $line =~  /^\s+$/;
	#chomp $line; # do not use if unix2dos has been run on the input files
	# remove leading space in OR (state)
	$line =~ s/ OR/OR/g;

	# remove blanks
	#$line =~ s/\s+,/,/g;
	#print "$line\n";

	my @data = split(/,/,$line);

	next unless @data;
	my $aptNum='';
	$aptNum = $data[APTNUM] if $data[APTNUM];
	chomp $aptNum;

	#print "Apt: |$aptNum|\n" if $aptNum;

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

	# the following fields will be useful for sorting
	my $key = $data[STREETLOC] . '-' . $data[STREETADDRESS] . '-' . $data[CITY] . '-' . $aptNum;

	push @{$addresses{$key}->{'NAMES'}{$data[LNAME]}}, [ $data[FNAME], $data[PHONE]];
	$addresses{$key}->{'CITY'} = $data[CITY];
	$addresses{$key}->{'STATE'} = $data[STATE];
	$addresses{$key}->{'ZIPCODE'} = $data[ZIPCODE];
	$addresses{$key}->{'STREETNUM'} = $data[STREETNUM];
	$addresses{$key}->{'STREETLOC'} = $data[STREETLOC];
	$addresses{$key}->{'STREETNAME'} = qq{$data[STREETNAME] $data[STREETDESG]};
	$addresses{$key}->{'STREETADDRESS'} = qq{$data[STREETADDRESS]};
	$addresses{$key}->{'APTNUM'} = $aptNum;

}


print 'Addresses: ' , Dumper(\%addresses) if $debug;

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
	print "### Working on $address\n" if $debug;

	# make a copy of the current record to simplify code
	my $data = $addresses{$address};
	print 'Work Data: ' , Dumper($data) if $debug;

	$cleanData->{$address}{'STREETLOC'} = $data->{'STREETLOC'};
	$cleanData->{$address}{'STREETNAME'} = $data->{'STREETNAME'};
	$cleanData->{$address}{'STREETNUM'} = $data->{'STREETNUM'};
	$cleanData->{$address}{'STREETADDRESS'} = $data->{'STREETADDRESS'};
	$cleanData->{$address}{'APT'} = $data->{'APTNUM'};
	$cleanData->{$address}{'CITY'} = $data->{'CITY'};
	$cleanData->{$address}{'STATE'} = $data->{'STATE'};
	$cleanData->{$address}{'ZIPCODE'} = $data->{'ZIPCODE'};

	# get count of different phone numbers
	my @lastNames = keys %{$data->{'NAMES'}};
	print '@lastNames: ' , Dumper(\@lastNames), "\n" if $debug;

	foreach my $lastName ( @lastNames ) {

		my %phoneHash;

		#$cleanData->{$address}{'LASTNAME'} = $lastName;

		my $firstNames = $data->{'NAMES'}{$lastName};
		print "== LastName: $lastName\n" if $debug;
		print "FirstNames: " , Dumper($firstNames) if $debug;

		foreach my $el ( 0..$#{$firstNames} ) {
			#print "phonetest: $firstNames->[$el][1]\n" if $debug;
			#print "fname: $firstNames->[$el][0]\n" if $debug;
			$phoneHash{$firstNames->[$el][1]} = 'Phone';  # dummy value	
		}

		#print 'Dumper %phoneHash: ' , Dumper(\%phoneHash), "\n" if $debug;
		#print 'keys %phoneHash: ' , join (' - ', keys %phoneHash), "\n" if $debug;

		my @phones = keys %phoneHash;
		print 'Phone Data: ' , join (' | ' , @phones), "\n" if $debug;

		my $phoneCount = $#phones;

		print "Last Names: ", join(' | ', @lastNames), "\n" if $debug;


		foreach my $el ( 0 ..$#{$firstNames}) {
			push @{$cleanData->{$address}{'NAMES'}{$lastName}}, $firstNames->[$el][0];
		}

		if ($phoneCount < 0 ) {
			$cleanData->{$address}{'PHONE'}{$lastName} = 'NA';
		} elsif ($phoneCount > 0 ) {
				foreach my $el ( 0 ..$#{$firstNames}) {
					print "LastName: $lastName\n" if $debug;
					$cleanData->{$address}{'PHONE'}{$lastName} .= qq{$firstNames->[$el][0] ->  $firstNames->[$el][1]  | };
				}
				$cleanData->{$address}{'PHONE'}{$lastName} = substr($cleanData->{$address}{'PHONE'}{$lastName},0,length($cleanData->{$address}{'PHONE'}{$lastName})-2);
		} else {
			$cleanData->{$address}{'PHONE'}{$lastName} .= $phones[0];
		}

	}

}

print 'CleanData: ' . Dumper($cleanData) if $debug;

print "StreetLoc,StreetNum,StreetName,Apt,FullAddress,City,State,ZipCode,LastName,FirstNames,Phones\n";

foreach my $address ( keys %{$cleanData} ) {

	# are there multiple last names?
	# print 2 records if so
	# 
	my @lastNameAry = (keys %{$cleanData->{$address}{'NAMES'}});
	foreach my $lastName ( @lastNameAry ) {
		print "$cleanData->{$address}{'STREETLOC'},";
		print "$cleanData->{$address}{'STREETNUM'},";
		print "$cleanData->{$address}{'STREETNAME'},";
		print "$cleanData->{$address}{'APT'},";
		print "$cleanData->{$address}{'STREETADDRESS'},";
		print "$cleanData->{$address}{'CITY'},";
		print "$cleanData->{$address}{'STATE'},";
		print "$cleanData->{$address}{'ZIPCODE'},";
		print "$lastName,";
		print join(' ',@{$cleanData->{$address}{'NAMES'}{$lastName}}),',';
		print $cleanData->{$address}{'PHONE'}{$lastName};

		print "\n";

	}
}


























