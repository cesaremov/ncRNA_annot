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
#inExt=".fastq.gz"

# Cluster params
nodes=1
ppn=1
mem="20G"

# FastQC parameters
params="-o $outPath --extract -f fastq -t 4"   #--contaminants contaminant_list.txt"

# Files to process
inFiles=`find $inPath -name '*fastq.gz'`

for inFile in $inFiles; do
  
    echo $inFile

   # logFile for each inFile
   base="`echo $inFile | sed 's/^.+\/|$inExt//'`.log"
   logFile="$logPath/base.log"
   
   echo $logFile
   
   # FastQC
   echo "FastQC"
   cmd0="fastqc $params $inFile"
   if [[ $mode == "local" ]]; then
      cmd=$cmd0 
   elif [[ $mode == "cluster" ]]; then
      cmd="echo 'cd \$PBS_O_WORKDIR; module load FastQC/0.11.2; $cmd0' | qsub -N FastQC -l nodes=1:ppn=1,mem=$mem,vmem=$mem -V"
   fi
   echo "running: $cmd"
   eval "date; $cmd"

done

# MultiQC if available
if which multiqc > /dev/null; then
   echo "MultiQC procedding"
   multiqc $outPath -o ./ncRNA/multiqc
fi

