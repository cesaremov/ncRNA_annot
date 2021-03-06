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
J=$(basename $0 .sh)
p="computes_standard"
N=1
n=32
qos="ipicyt"

# Files to process
inFiles="`ls -r $inPath/*$inPatt`"

for inFile in $inFiles; do

   echo $inFile

   # Get name
   name="${inFile/$inPatt/}.rnammer.gff"

   # Get logFile
   logFile="$name.log"

    if [[ -f $logFile ]]; then
      echo -e "$logFile already exists, continue...\n"
      continue
   fi
   
   # Run RNAmmer
   echo "RNAmmer"
   cmd0="~/bin/rnammer -S euk -multi -m tsu,lsu,ssu -gff $name < $inFile"
   if [[ $mode == "local" ]]; then
      cmd="$cmd0"
   elif [[ $mode == "cluster" ]]; then
      cmd="echo -e '#!/bin/bash \n $cmd0' | \
            sbatch -J $J -p $p -N $N --ntasks-per-node=$n --qos=$qos -o $logFile && touch $logFile"
   fi
   echo "running: $cmd"
   eval $cmd
 
done
   

