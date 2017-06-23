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
while [[ `find $inPath -name "*$inPatt" | wc -l` -ne `find $inPath -name "*log.txt" | wc -l` ]] || [[ `find $inPath -name "*log.txt" | wc -l` -lt $numFastq ]]; do

   echo -ne "\rPreproc not finished, waiting..."
   sleep 1

done

# Cluster params
nodes=1
ppn=4
mem="10G"

# Bam files
bamFiles=`find $inPath -name "*$inPatt"`

for inFile in $bamFiles; do

   echo $inFile

   outFile=${inFile/$inPath/$outPath}

   outPathBit=`dirname $outFile`

   mkdir -p $outPathBit

   # Filter out reads by XZ tag
   echo "Filtering out" 
   cmd0="samtools view -h --threads $ppn $inFile | grep -v $'XZ:f:0\t' | samtools view --threads $ppn -Sb - > $outFile && echo OK > ${outFile/$inPatt/}.log.txt"
   if [[ $mode == "local" ]]; then
      cmd=$cmd0 
   elif [[ $mode == "cluster" ]]; then
     cmd="echo 'cd \$PBS_O_WORKDIR; module load samtools/1.3.1; $cmd0' | qsub -N filter-bowtie -l nodes=1:ppn=1,mem=$mem,vmem=$mem -V"
   fi
   echo "running: $cmd"
   eval "date; $cmd"

done

