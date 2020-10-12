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
J=$(basename $0 .sh)
p="computes_standard"
N=1
n=32
qos="ipicyt"

# cmsearch rfam instruction
prog="cmsearch --noali --rfam --cpu $n --tblout"

# Files to process
inFiles="`ls -r $inPath/*$inPatt`"

# Process
for inFile in $inFiles; do
 
   echo $inFile
    
   # Get name 
   name=${inFile/$inPatt/}  # `echo $inFile | sed -E "s/.+\/|\.$inExt//g"`

   # Get outFile name
   outFile=${inFile/$inPatt/.rfam}

   # Get logFile names
   logFile="$outFile.log"

   if [[ -f $logFile ]]; then
      echo -e "$logFile already exists, continue...\n"
      continue
   fi

   # Infernal search, cmsearch 
   cmd0="$prog $outFile $rfam $inFile" 
   if [[ $mode == "local" ]]; then
      cmd="$cmd0" 
   elif [[ $mode == "cluster" ]]; then
      cmd="echo -e '#!/bin/bash \n $cmd0' | \
            sbatch -J $J -p $p -N $N --ntasks-per-node=$n --qos=$qos -o $logFile && touch $logFile"
   
   fi

   # Run
   echo -e "Running: $cmd\n"
   eval "date && $cmd"
 
done
 

