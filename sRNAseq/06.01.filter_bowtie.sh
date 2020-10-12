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
inPath="$bit/bowtie_ShortStack"
outPath="$bit/filter_bowtie"

mkdir -p $outPath

# Patts
inPatt=".bam"

# Check preproc
numFastq=`find $bit/Raw/ -name "*fastq.gz" | wc -l`
while [[ `find $inPath -name "*$inPatt" | wc -l` -ne `find $inPath -name "*log" | wc -l` ]] || [[ `find $inPath -name "*log" | wc -l` -lt $numFastq ]]; do

   echo -ne "\rPreproc not finished, waiting..."
   sleep 1

done

# Cluster params
J=$(basename $0 .sh)
p="computes_standard"
N=1
n=8
qos="ipicyt"

# Bam files
bamFiles=`find $inPath -name "*$inPatt"`

for inFile in $bamFiles; do

   echo $inFile

   outFile=${inFile/$inPath/$outPath}

   outPathBit=`dirname $outFile`

   mkdir -p $outPathBit

      # Get logFile
   logFile="$outFile.log"

   if [[ -f $logFile ]]; then
      echo -e "$logFile already exists, continue...\n"
      continue
   fi   

   # Filter out reads by XZ tag
   cmd0="samtools view -h --threads $n $inFile | grep -v $'XZ:f:0\t' | samtools view --threads $n -Sb - > $outFile && echo OK > $logFile"
   if [[ $mode == "local" ]]; then
      cmd=$cmd0 
   elif [[ $mode == "cluster" ]]; then
      cmd="echo -e '#!/bin/bash \n $cmd0' | \
            sbatch -J $J -p $p -N $N --ntasks-per-node=$n --qos=$qos -o $logFile && touch $logFile"
   fi
   
   # Run
   echo -e "Running: $cmd\n"
   eval "date && $cmd"

done

