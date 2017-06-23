#!/bin/bash

usage(){
   echo "Usage: $0 -b/--base -m/--minsize --mode"
   echo "	-b/--base:		index basename"
   echo "	-m/--minsize:		minimum size to split multifasta file"
   echo "	--mode:			mode to process"
   echo "	-h/--			help print this usage message"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 6 ]]; then
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
        -b | --base )		base=$2
				shift;;
	-m | --minsize )	minsize=$2
				shift;;
 	--mode )		mode=$2
				shift;;
        -h | --help )           usage
                                exit;;
        * )                     usage
                                exit 1
    esac
    shift
done

# Paths
bit="./ncRNA"
#inPath=`dirname $genome`
#outBit="$bit/Genome"
inPath="$bit/Genome"
outPath="$inPath/split_genome"

mkdir -p $outPath

# Patts
inPatt=".fa"

# Setting up base name
base=${base//./_}

# Split genome fastq
echo "Spliting fasta"    
cmd0="splitMfasta.pl --minsize=$minsize --outputpath=$outPath $inPath/$base.fa && echo 'OK' > $outPath/log.txt"
if [[ $mode == "local" ]]; then
   cmd="$cmd0"
elif [[ $mode == "cluster" ]]; then
  cmd="echo 'cd \$PBS_O_WORKDIR; $cmd0' | qsub -V -N splitGenome" 
fi
echo "running: $cmd"
eval $cmd
   



