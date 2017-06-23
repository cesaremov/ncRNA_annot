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
while [[ `find $inPath -name "*$inPatt" | wc -l` -ne `find $inPath -name "*log.txt" | wc -l` ]] || [[ `find $inPath -name "*log.txt" | wc -l` -lt $numFastq ]]; do

   echo -ne "\rPreproc not finished, waiting..."
   sleep 3

done

# Cluster parameters
nodes=1
ppn=4
mem="40G"

# File to process
bamFiles=`find $inPath -name "*$inPatt"`

# Concat files
echo "Concat files"
echo "test"
echo $bamFiles
echo "test"
cmd0="samtools merge --threads $ppn $outPath/all.0$inPatt `echo $bamFiles`;
      samtools view -F4 -h --threads $ppn $outPath/all.0$inPatt | samtools view -Sb - > $outPath/all$inPatt;
      samtools index -b $outPath/all.bam $outPath/all$inPatt.bai;
      rm $outPath/all.0$inPatt && echo OK > $outPath/log.txt"
if [[ $mode == "local" ]]; then
   cmd=$cmd0 
elif [[ $mode == "cluster" ]]; then
  cmd="echo 'cd \$PBS_O_WORKDIR; module load samtools/1.3.1; $cmd0' | qsub -N samtools -l nodes=$nodes:ppn=$ppn,mem=$mem,vmem=$mem -V" 
fi
echo "running: $cmd"
eval "date; $cmd"   


