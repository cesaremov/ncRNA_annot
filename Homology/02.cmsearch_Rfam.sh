#!/bin/bash

usage(){
   echo "Usage: $0 -r/--rfam -m/--mode"
   echo "	-r/--rfam:		rfam file"
   echo "	-m/--mode:		mode to process fa files (local/cluster)"
   echo "	-h/--help print this usage message"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 4 ]]; then
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
	-r | --rfam )		rfam=$2
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
bit="./ncRNA/Genome"
inPath="$bit/split_genome"
#logPath="logs.Rfam"

#mkdir -p $logPath

# Patts
inPatt=".fa"

# Check if genome splited
while [[ ! -e $inPath/log.txt ]]; do

   echo -ne "\rNot ready yet, wating... "
   sleep 1

done

# Cluster parameters
nodes=1
ppn=10
mem="20G"
walltime="1200:00:00"

# cmsearch rfam instruction
prog="cmsearch --rfam --cpu $ppn --tblout"

# Files to process
inFiles="`ls -r $inPath/*$inPatt`"

# Process
for inFile in $inFiles; do
 
   echo $inFile
    
   # Get name 
   name=${inFile/$inPatt/}  # `echo $inFile | sed -E "s/.+\/|\.$inExt//g"`

   # Get outFile name
   outFile=${inFile/$inPatt/.rfam}

   # Infernal search, cmsearch 
   echo "CMsearch"
   cmd0="$prog $outFile $rfam $inFile" 
   if [[ $mode == "local" ]]; then
      cmd="$cmd0" 
   elif [[ $mode == "cluster" ]]; then
      cmd="echo 'cd \$PBS_O_WORKDIR; module load infernal/1.1.1; $cmd0' | \
            qsub -N CMsearch -l nodes=$nodes:ppn=$ppn,mem=$mem,vmem=$mem,walltime=$walltime -V -j oe -o $logPath/$name.log"
   fi
   echo "running: $cmd"
   eval $cmd
 
done
 

