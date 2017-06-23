#/bin/bash

usage(){
   echo "Usage: $0 -b/--base -y/--yrna -m/--mode"
   echo "	-b/--base:		index basename"
   echo "	-y/--yrna:		yRNA sequences (fasta)"
   echo "	-m/--mode: 		mode to process"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 6 ]]; then
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
        -y | --yrna )		yrna=$2
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
bit="./ncRNA/"
inPath="$bit/Genome"
outPath="$inPath"

# Patts

# Check if genome splited
while [[ ! -e $inPath/log.txt ]]; do

   echo -ne "\rNot ready yet, wating... "
   sleep 1

done

# Setting up base name
base="${base//./_}"

# Cluster parameters
nodes=1
ppn=1
mem="10G"

# Blast yRNA sequences
echo "Blast yRNA sequences"
cmd0="blastn -outfmt 6 -db $inPath/$base -query $yrna > $outPath/yRNA.tab"
if [[ $mode == "local" ]]; then
   cmd=$cmd0
elif [[ $mode == "cluster" ]]; then
   cmd="echo 'cd \$PBS_O_WORKDIR; module load ncbi-blast+/2.2.31; $cmd0' | qsub -N yRNA_blast -l nodes=$nodes:ppn=$ppn,mem=$mem,mem=$mem"
fi
echo "running: $cmd"
eval "date; $cmd"





