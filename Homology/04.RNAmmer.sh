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
bit="./ncRNA/Genome"
inPath="$bit/split_genome"
outPath=$inPath

# Patts
inPatt=".fa"

# Check if genome splited
while [[ ! -e $inPath/log.txt ]]; do

   echo "Not ready yet, wating... "
   sleep 3

done

# Cluster parameters
nodes=1
ppn=1
mem="20G"

# Files to process
inFiles="`ls -r $inPath/*$inPatt`"

for inFile in $inFiles; do

   echo $inFile

   # Get name
   name=${inFile/$inPatt/}
   
   # Run RNAmmer
   echo "RNAmmer"
   cmd0="~/bin/rnammer -S euk -multi -m tsu,lsu,ssu -gff $name.rnammer.gff < $inFile"
   if [[ $mode == "local" ]]; then
      cmd="$cmd0"
   elif [[ $mode == "cluster" ]]; then
     cmd="echo 'cd \$PBS_O_WORKDIR; $cmd0' | qsub -V -N RNAmmer -l nodes=$nodes:ppn=$ppn,mem=$mem,vmem=$mem" 
   fi
   echo "running: $cmd"
   eval $cmd
 
done
   

