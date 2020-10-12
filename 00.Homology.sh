#!/bin/bash

usage(){
   echo "Usage: $0 -g/--genome -b/--base -m/--minsize -r/--rfam -M/--mature --mapmiPath --mode"
   echo "All arguments are mandatory"
   echo "       -g/--genome     genome file"
   echo "	-b/--base	indexbasename"
   echo "	-m/--minsize	minimum size to split multifasta file"
   echo "	-r/--rfam	Rfam. cm file"
   echo "	-M/--mature	miRNA mature sequences fasta file"
   echo "	--mapmiPath	path to MapMi"
   echo "       --mode		mode to process [local/cluster]"
   echo "	-h/--help 	print this usage message"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 14 ]]; then
   echo "Number of arguments incorrect"
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
        -g | --genome )         genome=$2
                                shift;;
        -b | --base )		base=$2
				shift;;
        -m | --minzise )        minsize=$2
                                shift;;
        -r | --rfam )       	rfam=$2
                                shift;;
        -M | --mature )         mature=$2
                                shift;;
        --mapmiPath )         	mapmiPath=$2
                                shift;;
	#-y | --yrna )		yrna=$2
	#			shift;;
        --mode )		mode=$2
                                shift;;
        -h | --help )           usage
                                exit;;
        * )                     usage
                                exit 1
    esac
    shift
done

# Processing Genome
echo "Setting up and processing Genome information"
cmd="00.procGenome.sh -g $genome -b $base -m $mode"
echo "running: $cmd"
eval "date; $cmd"

# Split genome
echo "Splitting genome"
cmd="01.split_genome.sh -b $base -m $minsize --mode $mode"
echo "running: $cmd"
eval "date; $cmd"

# Rfam
echo "Infernal-Rfam"
cmd="02.cmsearch_Rfam.sh -r $rfam -m $mode"
echo "running: $cmd"
eval "date; $cmd"

# tRNAscan-SE
echo "tRNAscan-SE"
cmd="03.tRNAscan.sh -m $mode"
echo "running: $cmd"
eval "date; $cmd"

# RNAmmer
echo "RNAmmer"
cmd="04.RNAmmer.sh -m $mode"
echo "running: $cmd"
eval "date; $cmd"

# MapMi
echo "MapMi"
cmd="05.MapMi.sh -b $base --mapmiPath $mapmiPath -M $mature -m $mode"
echo "running: $cmd"
eval "date; $cmd"

# RepeatMasker
echo "RepeatMasker"
cmd="07.RepeatMasker.sh -m $mode"
echo "running: $cmd"
eval "date; $cmd"


# Clean 
rm -rf *cf
rm -rf temp*



