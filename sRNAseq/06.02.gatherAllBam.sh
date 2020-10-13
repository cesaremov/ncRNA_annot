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
inPath="$bit/filter_bowtie"
outPath="$bit/gatherAllBam"

mkdir -p $outPath

# Patts
inPatt=".bam"

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
n=32
qos="ipicyt"

# File to process
bamFiles=`find $inPath -name "*$inPatt"`

# Set logFile
logFile="$outPath/gatherAllBam.log"
if [[ -e $logFile ]]; then
  echo "$logFile already exists, exiting..." 
  exit
fi


# Concat files
echo "Concat files"
echo $bamFiles
cmd0="samtools merge --threads $n $outPath/all.0$inPatt `echo $bamFiles`;
      samtools view -F4 -h --threads $n $outPath/all.0$inPatt | samtools view -Sb - > $outPath/all$inPatt;
      samtools index -b $outPath/all.bam $outPath/all$inPatt.bai;
      rm $outPath/all.0$inPatt && echo OK > $logFile"

if [[ $mode == "local" ]]; then
   cmd=$cmd0 
elif [[ $mode == "cluster" ]]; then
   cmd="echo -e '#!/bin/bash \n $cmd0' | \
            sbatch -J $J -p $p -N $N --ntasks-per-node=$n --qos=$qos -o $logFile && touch $logFile"
fi

# Run
echo "Running: $cmd"
eval "date && $cmd"   


