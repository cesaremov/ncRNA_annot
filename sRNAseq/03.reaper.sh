#!/bin/bash

usage(){
   echo "Usage: $0 -a/--adapter -t/--tabu -m/--mode"
   echo "	-a/--adapter:	3pa sequence adapter"
   echo "	-t/--tabu:	5pa sequence"
   echo "	-m/--mode:	mode to process"
   echo "	-h/--help 	print this usage message"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 6 ]]; then
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
        -a | --adapter )	pa=$2
				shift;;
	-t | --tabu )		tabu=$2
				shift;;
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
inPath="$bit/Raw/"
outPath="$bit/reaper"

mkdir -p $outPath

# Cluster parameters
mem="10G"
vmem=$mem
nodes=1
ppn=1

# Reaper parameters
params="-geom no-bc -3pa $pa -3p-global 12/2/1 -3p-prefix 8/2/1 -3p-head-to-tail 1 -nnn-check 3/5 -dust-suffix 20 -polya 5 -qqq-check 35/10 -tabu $tabu -mr-tabu 14/2/1"

logFile="Reaper.log"

# Files to process
inFiles=`find $inPath -name "*fastq.gz"`

for inFile in $inFiles; do

   echo $inFile 

   # Get base
   base=`basename $inFile`
   base=${base/.*/}

   echo $base

   # Reaper reads
   echo "Reaper"
   cmd0="reaper -i $inFile -basename $outPath/$base $params && echo 'OK' > $outPath/$base.log.txt"
   if [[ $mode == "local" ]]; then
      cmd=$cmd0
   elif [[ $mode == "cluster" ]]; then
      cmd="echo 'cd \$PBS_O_WORKDIR; $cmd0' | qsub -V -N Reaper -l nodes=$nodes:ppn=$ppn,mem=$mem,vmem=$mem" 
   fi
   echo "running: $cmd"
   eval $cmd  

done

