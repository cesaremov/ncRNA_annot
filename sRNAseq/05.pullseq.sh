#!/bin/bash

usage(){
   echo "Usage: $0 -l/--lower -u/--upper -m/--mode"
   echo "	-l/--lower:	require read length >= <int>"
   echo "	-u/--upper	require read length <= <int>"
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
        -l | --lower )		lower=$2
				shift;;
	-u | --upper )		upper=$2
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
inPath="$bit/reaper"
outPath="$bit/pullseq"

mkdir -p $outPath

# Patts
inPatt=".lane.clean.gz"
outPatt=".fq.gz"

# Check preproc
numFastq=`find $bit/Raw/ -name "*fastq.gz" | wc -l`
while [[ `find $inPath -name "*$inPatt" | wc -l` -ne `find $inPath -name "*log" | wc -l` ]] || [[ `find $inPath -name "*log" | wc -l` -lt $numFastq ]]; do

   echo -ne "\rPreproc not finished, waiting..."
   sleep 3

done

# Cluster params
J=$(basename $0 .sh)
p="computes_standard"
N=1
n=1
qos="ipicyt"

# Files to process
inFiles=`find $inPath/ -name "*$inPatt"`

for inFile in $inFiles; do

   echo $inFile

   file0=${inFile/$inPatt/}
   base0=`basename $file0`
   base=${base0/\./_}

   # Get logFile
   logFile="$outPath/$base.pullseq.log"

   if [[ -f $logFile ]]; then
      echo -e "$logFile already exists, continue...\n"
      continue
   fi

   # Execute pullseq to filter out reads
   cmd0="pullseq -i $inFile -m $lower -a $upper | gzip -c - > $outPath/$base$outPatt && echo OK > $logFile"
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


