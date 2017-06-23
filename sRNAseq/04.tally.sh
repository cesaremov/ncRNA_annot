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
while [[ `find $inPath -name "*$inExt" | wc -l` -ne `find $inPath -name "*log.txt" | wc -l` ]] || [[ `find $inPath -name "*log.txt" | wc -l` -lt $numFastq ]]; do

   echo -ne "\rPreproc not finished, waiting..."
   sleep 1

done

# Cluster resources
nodes=1
ppn=1
mem="10G"

# Tally parameters
format='">seq_%I_w%L_x%C%n%R%n"'
params="-l $lower -u $upper -tri 50 -format $format" #-record-format %R%t%C"

# Files to process
inFiles=`find $inPath -name "*$inExt"`

for inFile in $inFiles; do
 
   echo $inFile
 
   outBase=${inFile%%$inExt}
   outBase=${outBase/$inPath/$outPath}
   echo $outBase

   # Tally 
   echo "Tally"
   cmd0="tally -i $inFile -o $outBase$outExt -sumstat $outBase.sumstat $params && echo OK > $outBase.log.txt"
   if [[ $mode == "local" ]]; then
      cmd=$cmd0
   elif [[ $mode == "cluster" ]]; then
      cmd="echo 'cd \$PBS_O_WORKDIR; $cmd0' | qsub -V -N Tally -l nodes=$nodes:ppn=$ppn,mem=$mem,vmem=$mem "
   fi 
   echo "running: $cmd"
   eval $cmd
   
done





