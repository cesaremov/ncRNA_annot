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
while [[ `find $inPath -name "*$inPatt" | wc -l` -ne `find $inPath -name "*log.txt" | wc -l` ]] || [[ `find $inPath -name "*log.txt" | wc -l` -lt $numFastq ]]; do

   echo "Preproc not finished, waiting..."
   sleep 3

done

# Cluster parameters
nodes=1
ppn=1
mem="10G"

# Files to process
inFiles=`find $inPath -name "*$inPatt"`

for inFile in $inFiles; do

   echo $inFile

   file0=${inFile/$inPatt/}
   base0=`basename $file0`
   base=${base0/\./_}

   # Execute pullseq to filter out reads
   echo "pullseq"
   cmd0="pullseq -i $inFile -m $lower -a $upper | gzip -c - > $outPath/$base$outPatt && echo OK > $outPath/$base.log.txt"
   if [[ $mode == "local" ]]; then
      cmd=$cmd0
   elif [[ $mode == "cluster" ]]; then
      cmd="echo 'cd \$PBS_O_WORKDIR; module load pullseq/1.0.2; $cmd0' | qsub -N pullseq -l nodes=$nodes:ppn=$ppn,mem=$mem,vmem=$mem"
   fi
   echo "running: $cmd"   
   eval "date; $cmd"

done


