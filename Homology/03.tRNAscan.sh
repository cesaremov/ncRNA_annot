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
#logPath="logs.tRNAscan"

#mkdir -p $logPath

# Patts
inPatt=".fa"

# Check if genome splited
while [[ ! -e $inPath/log.txt ]]; do

   echo "Not ready yet, wating... "
   sleep 3

done

# Cluster params
nodes=1
ppn=1
mem="20G"

# Files to process
inFiles="`ls -r $inPath/*$inPatt`"

# Process
for inFile in $inFiles; do

   echo $inFile

   # Get name   
   name=${inFile/$inPatt/} #`echo $inFile | gsed -r "s/.+\/|\.$inExt//g"`
   
   # Continue if log file exists
   #if [[ -f $logPath/$name.log ]]; then
   #   echo "$logPath/$name.log already exists, won't run again!";
   #   continue
   #fi
   
   # Local mode
   echo "tRNAscan-SE"
   cmd0="~/bin/tRNAscan-SE -o $name.trnas $inFile"
   if [[ $mode == "local" ]]; then
      cmd=$cmd0
   elif [[ $mode == "cluster" ]]; then  
      cmd="echo 'cd \$PBS_O_WORKDIR; $cmd0' | qsub -V -N tRNAscan-SE -l nodes=$nodes:ppn=$ppn,mem=$mem,vmem=$mem -V -j oe -o $logPath/$name.log"
   fi   
   echo "running: $cmd"
   eval $cmd
   
done

