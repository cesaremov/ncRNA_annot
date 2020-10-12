#!/bin/bash

usage(){
   echo "Usage: $0 -b/--base -m/--minsize --mode"
   echo "	-b/--base:		index basename"
   echo "	-m/--minsize:		minimum size to split multifasta file"
   echo "	--mode:			mode to process"
   echo "	-h/--			help print this usage message"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 6 ]]; then
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
        -b | --base )		base=$2
				shift;;
	-m | --minsize )	minsize=$2
				shift;;
 	--mode )		mode=$2
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
#inPath=`dirname $genome`
#outBit="$bit/Genome"
inPath="$bit/Genome"
outPath="$inPath/split_genome"

mkdir -p $outPath

# Patts
inPatt=".fa"


# Cluster params
J=$(basename $0 .sh)
p="computes_standard"
N=1
n=1
qos="ipicyt"


# Setting up base name
base=${base//./_}

# Check if already processed
if [[ -f $outPath/log.txt ]]; then
   echo -e "split_genome $outPath/log.txt already exists, exiting...\n"
   exit
fi

# Split genome fastq
echo "Spliting fasta"    
cmd0="splitMfasta.pl --minsize=$minsize --outputpath=$outPath $inPath/$base.fa && echo 'OK' > $outPath/log.txt"

# Set logFile
logFile="$outPath/$(basename $outPath).log"

if [[ $mode == "local" ]]; then
   cmd="$cmd0"
elif [[ $mode == "cluster" ]]; then
   cmd="echo -e '#!/bin/bash \n $cmd0' | \
            sbatch -J $J -p $p -N $N -n $n --qos=$qos -o $logFile && touch $logFile"
fi

# Run
echo "running: $cmd"
eval $cmd
   



