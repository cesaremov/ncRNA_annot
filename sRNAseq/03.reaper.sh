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

# Cluster params
J=$(basename $0 .sh)
p="computes_standard"
N=1
n=32
qos="ipicyt"

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

   # Get logFile
   logFile="$outPath/$base.log"

   if [[ -f $logFile ]]; then
      echo -e "$logFile already exists, continue...\n"
      continue
   fi  

   # Reaper reads
   echo "Reaper"
   cmd0="reaper -i $inFile -basename $outPath/$base $params && echo 'OK' &> $logFile"
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

