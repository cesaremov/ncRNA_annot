#!/bin/bash

usage(){
   echo "Usage: $0 -m/--mode"
   echo "	-m/--mode:	mode to process"
   echo "	-h/--help 	print this usage message"
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
inPath="$bit/Raw"
outPath="$bit/fastqc"
#logPath="logs.$outPath"

mkdir -p $outPath
#mkdir -p $logPath

# Patts
inExt=".fastq.gz"

# Cluster params
J=$(basename $0 .sh)
p="computes_standard"
N=1
n=1
qos="ipicyt"

# FastQC parameters
params="-o $outPath --extract -f fastq -t 4"   #--contaminants contaminant_list.txt"

# Files to process
inFiles=`find $inPath -name '*fastq.gz'`

for inFile in $inFiles; do
  
    echo $inFile

   # logFile for each inFile
   base=$(basename $inFile $inExt)
   logFile="$outPath/$base.log"
   echo $logFile   

   if [[ -f $logFile ]]; then
      echo -e "$logFile already exists, continue...\n"
      continue
   fi 
   
   # FastQC
   echo "FastQC"
   cmd0="fastqc $params $inFile > $logFile"
   if [[ $mode == "local" ]]; then
      cmd=$cmd0 
   elif [[ $mode == "cluster" ]]; then
      cmd="echo -e '#!/bin/bash \n $cmd0' | \
           sbatch -J $J -p $p -N $N --ntasks-per-node $n --qos=$qos -o $logFile && touch $logFile"
   fi

   # Run
   echo "Running: $cmd"
   eval "date && $cmd"

done

# MultiQC if available
if which multiqc > /dev/null; then
   echo "MultiQC processing"
   multiqc $outPath -o ./ncRNA/multiqc
fi

