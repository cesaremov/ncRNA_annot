#!/bin/bash

usage(){
   echo "Usage: $0 -b/--base --dicermin --dicermax --mincov --pad -m/--mode"
   echo "	-b/--base	index basename"
   echo "	--dicermin:	dicer min"
   echo "	--dicermax: 	dicer max"
   echo "	--mincov:	minimum aligments"
   echo "	--pad:		padding between clusters"
   echo "	-m/--mode:	mode to process"
   echo "	-h/--help 	print this usage message"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 12 ]]; then
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
        -b | --base )		base=$2
				shift;;
	--dicermin )		dicermin=$2
				shift;;
	--dicermax )		dicermax=$2
				shift;;
	--mincov )		mincov=$2
				shift;;
	--pad )			pad=$2
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
inPathGenomes="$bit/Genome"
inPathAlign="$bit/gatherAllBam"
outPath="$bit/shortstack"

rm -rf $outPath

# Patts
inPatt=".bam"

# Cheack gathering preproc
while [[ ! -e $inPathAlign/log.txt ]]; do

   echo -ne "\rGathering has not finished, waiting..."
   sleep 3
   
done

# Setting up base name
base="${base//./_}"

# Cluster params
nodes=1
ppn=1
mem="20G"
vmem=$mem
walltime="6720:00:00"

# ShortStack line
ssLine="ShortStack --genomefile $inPathGenomes/$base.fa --dicermin $dicermin --dicermax $dicermax --mincov $mincov --pad $pad"

# Files to process
inFiles=`ls $inPathAlign/all$inPatt`

for bamFile in $inFiles; do

   echo $bamFile
   

   # ShortStack processing
   echo "ShortStack"
   cmd0="$ssLine --bamfile $bamFile --outdir $outPath"
   if [[ $mode == "local" ]]; then
      cmd=$cmd0 
   elif [[ $mode == "cluster" ]]; then
     cmd="echo 'cd \$PBS_O_WORKDIR; module load bowtie/1.1.0; module load samtools/1.3.1; module load Vienna/2.2.5; $cmd0' | qsub -N ShortStack -l nodes=1:ppn=1,mem=$mem,vmem=$mem,walltime=$walltime -V"
   fi 
   echo "running: $cmd"
   eval "date; $cmd"

done



