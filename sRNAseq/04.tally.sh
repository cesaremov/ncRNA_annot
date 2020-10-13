#!/bin/bash

usage(){
   echo "Usage: $0 -l/--lower -u/--upper -m/--mode"
   echo "	-l/--lower:	require read length >= <int>"
   echo "	-u/--upper:	require read length <= <int>"
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

# Patahs
bit="./ncRNA"
inPath="$bit/reaper"
outPath="$bit/tally"

mkdir -p $outPath

# Patts
inExt=".lane.clean.gz"
outExt=".fa.gz"

# Check preproc
numFastq=`find $bit/Raw/ -name "*fastq.gz" | wc -l`
while [[ `find $inPath -name "*$inExt" | wc -l` -ne `find $inPath -name "*log" | wc -l` ]] || [[ `find $inPath -name "*log" | wc -l` -lt $numFastq ]]; do

   echo -ne "\rPreproc not finished, waiting..."
   sleep 1

done



# Cluster params
J=$(basename $0 .sh)
p="computes_standard"
N=1
n=1
qos="ipicyt"

# Tally parameters
format='">seq_%I_w%L_x%C%n%R%n"'
params="-l $lower -u $upper -tri 50 -format $format" #-record-format %R%t%C"

# Files to process
inFiles=`find $inPath -name "*$inExt"`

for inFile in $inFiles; do
 
   echo $inFile
 
   outBase=${inFile%%$inExt}
   outBase=${outBase/$inPath/$outPath}
   
   # Get logFile
   logFile="$outBase.tally.log"

   if [[ -f $logFile ]]; then
      echo -e "$logFile already exists, continue...\n"
      continue
   fi

   # Tally 
   echo "Tally"
   cmd0="tally -i $inFile -o $outBase$outExt -sumstat $outBase.sumstat $params && echo OK > $logFile"
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





