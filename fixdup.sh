#!/bin/bash

dataDir=data
outputDir=output
mkdir -p $outputDir


for datafile in ${dataDir}/*.csv
do
	fileName=$(basename $datafile )
	baseFile=$(echo $fileName | cut -f1 -d\. )
	outFile=${outputDir}/${baseFile}.csv
	echo outFile: $outFile

	echo " ## Working on $fileName "

	./fixdup.pl < $datafile > $outFile

done


