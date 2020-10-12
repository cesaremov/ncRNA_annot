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
J=$(basename $0 .sh)
p="computes_standard"
N=1
n=16
qos="ipicyt"

# Process
for inFile in $inFiles; do
   
   echo $inFile

    # Get logFile names
    logFile="$inFile.repeatmasker.log"

   if [[ -f $logFile ]]; then
      echo -e "$logFile already exists, continue...\n"
      continue
   fi

   # RepeatMasker
   cmd0="RepeatMasker -e hmmer -gff -pa $n -s -dir $(dirname $inFile) $inFile" # -species
   if [[ $mode == "local" ]]; then 
      cmd=$cmd0
   elif [[ $mode == "cluster" ]]; then
   cmd="echo -e '#!/bin/bash \n $cmd0' | \
            sbatch -J $J -p $p -N $N --ntasks-per-node=$n --qos=$qos -o $logFile && touch $logFile"

   fi

   # Run
   echo "Running: $cmd"
   eval "date && $cmd"

done


