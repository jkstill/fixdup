#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

# check that all rows have the same number of fields as the header lind
# this for csv files in data-2018-06


my $header=<>;
chomp $header;

my @headers=split(/,/,$header);

# this is the number of fields -1 
# actually the last element number, and they start at 0
my $fieldCount = $#headers;

my @a;

while(<>) {

	chomp;

	@a = split(/,/);

	if ($#a != $fieldCount) {
		print "Line $. - field count of $#a should be $fieldCount\n";
	}

}

