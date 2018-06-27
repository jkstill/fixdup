#!/bin/bash

dataDir=data-2018-06
outputDir=output-2018-06
mkdir -p $outputDir


for datafile in ${dataDir}/*.csv
do
	fileName=$(basename $datafile )
	baseFile=$(echo $fileName | cut -f1 -d\. )
	outFile=${outputDir}/${baseFile}.csv
	echo outFile: $outFile

	echo " ## Working on $fileName "

	./fixdup-2018.pl < $datafile > $outFile

	echo '======================'

done


