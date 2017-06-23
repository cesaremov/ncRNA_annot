#!/bin/bash

usage(){
   echo "Usage: $0 -g/--genome -b/--base -m/--mode"
   echo "	-g/--genome:		.fa | .fa.gz file"
   echo "	-b/--base:		index basename"
   echo "	-m /--mode:		mode to process"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 6 ]]; then
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
        -g | --genomeFile )	genome=$2
				shift;;
        -b | --base )		base=$2
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
#inPath=`dirname $genome`
outBit="./ncRNA"
outPath="$outBit/Genome"

mkdir -p $outPath

# Redefine base
#base="$outPath/$base0"

# Setting up base name
base="${base//./_}"

# Creating re-named link to genome file
echo "Linking"
genome=$(cd "$(dirname "$genome")"; pwd)/$(basename "$genome")
ln -sf $genome $outPath/$base.fa

# Cheack if genome file compressed
if [[ $genome =~ \.gz$ ]]; then
   echo "Uncompressing $genome"
   gunzip $genome
fi
 
# Cluster parameters
nodes=1
ppn=1
mem="10G"
  
# Bowtie index
echo "Creating bowtie index"
cmd0="bowtie-build $outPath/$base.fa $outPath/$base; bowtie-inspect -s $outPath/$base | grep '^Seq' | cut -f 2,3 > $outPath/$base.chrlens && echo 'OK' > $outPath/log.txt"
if [[ $mode == "local" ]]; then
   cmd="$cmd0"
elif [[ $mode == "cluster" ]]; then
  cmd="echo 'module load bowtie/1.1.0; cd \$PBS_O_WORKDIR; $cmd0' | qsub -V -l nodes=$nodes:ppn=$ppn,mem=$mem,vmem=$mem -N bowtie-build.$base" 
fi
echo "running: $cmd"
eval "date; $cmd"

# Blast database
#echo "Creating blast database"
#cmd0="makeblastdb -dbtype nucl -in $outPath/$base.fa -out $outPath/$base"
#if [[ $mode == "local" ]]; then
#   cmd="$cmd0"
#elif [[ $mode == "cluster" ]]; then
#  cmd="echo 'module load ncbi-blast+/2.2.31; cd \$PBS_O_WORKDIR; $cmd0' | qsub -V -l nodes=$nodes:ppn=$ppn,mem=$mem,vmem=$mem -N makeblastdb.$base" 
#fi
#echo "running: $cmd"
#eval "date; $cmd"



