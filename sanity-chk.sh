#!/bin/bash

for f in data-2018-06/*.csv
do
	echo
	echo working on $f
	echo

	./sanity-chk.pl < $f
done

