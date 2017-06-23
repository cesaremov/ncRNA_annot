#!/bin/bash

usage(){
   echo "Usage: $0 -m/--mode"
   echo "	-m/--mode:		mode to process fa files (local/cluster)"
   echo "	-h/--help print this usage message"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 2 ]]; then
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
	-m | --mode )		mode=$2
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
inPath="$bit/Genome/split_genome"

# Patts
inPatt=".fa"

# Check if genome index
while [[ ! -e $inPath/log.txt ]]; do

   echo -ne "\rNot ready yet, wating... "
   sleep 1

done

# Files to process
inFiles="`ls -r $inPath/*$inPatt`"

# Cluster parameters
nodes=1
ppn=4
mem="50G"

# Process
for inFile in $inFiles; do
   
   echo $inFile

   # RepeatMasker
   echo "RepeatMasker"
   cmd0="RepeatMasker -gff -pa $ppn -s -species elegans -dir `dirname $inFile` $inFile"
   if [[ $mode == "local" ]]; then 
      cmd=$cmd0
   elif [[ $mode == "cluster" ]]; then
      cmd="echo 'cd \$PBS_O_WORKDIR; module load RepeatMasker/4.0; $cmd0' | qsub -N RepeatMasker -l nodes=1:ppn=$ppn,mem=$mem,vmem=$mem"
   fi
   echo "running: $cmd"
   eval "date; $cmd"

done


