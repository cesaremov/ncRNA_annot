#!/bin/bash

usage(){
   echo "Usage: $0 -b/--base --mapmiPath -M/--Mature -m/--mode"
   echo "	-b/--base:		basename"
   echo "	--mapmiPath:		path to mapmi"
   echo "	-M/--mature:		mature microRNA sequences"
   echo "	-m/--mode:		mode to process fa files (local/cluster)"
   echo "	-h/--help print this usage message"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 8 ]]; then
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
	-b | --base )		base0=$2
				shift;;
	--mapmiPath )		mapmiPath=$2
				shift;;
	-M | --mature )		mature0=$2
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
inPath="`pwd`/$bit"
outPath="$inPath"

# Patts
inPatt=".fa"
ebwtPatt=".ebwt"

# Check if genome index exists
while [[ ! -e $inPath/log.txt ]]; do

   echo -ne "\rNot ready yet, wating..."
   sleep 3

done

# Redefine base
#base="$outPath/$base0"

# Setting up base name
base0="${base0//./_}"
base="$outPath/$base0"

# Mature sequences
mature="`dirname $mature0 | cd | pwd`/$mature0"

# Set cluste params
nodes=1
ppn=1
mem="10G"
vmem=$mem

# Create links from MapMi to genomesPath
echo "Cleanning previous MapMi results"
rm -rf $mapmiPath/RawData/Others

# Set up
echo "Setting up"
mkdir -p $mapmiPath/RawData/Others
ln -sf $base$inPatt $mapmiPath/RawData/Others/
b="`basename $base`"
ebwts=`ls $base*$ebwtPatt`
for ebwt in $ebwts; do
   ebwtBase=`basename $ebwt`
   ebwtBase="$b.fa.bowtie${ebwtBase/$b/}"
   ln -sf $ebwt $mapmiPath/RawData/Others/$ebwtBase
done

# Dust mature sequences
#$mapmiPath/HelperPrograms/
dust3 $mature > $mature.dusted

# Change to MapMi path
cd $mapmiPath

# MapMi line
echo "MapMi"
cmd0="perl MapMi-MainPipeline-v159-b32.pl --queryFile $mature --outputPrefix $base.mapmi"
if [[ $mode == "local" ]]; then
   cmd=$cmd0
elif [[ $mode == "cluster" ]]; then
   cmd="echo 'cd \$PBS_O_WORKDIR; $cmd0' | qsub -V -N MapMi -l nodes=$nodes:ppn=$ppn,mem=$mem,vmem=$vmem"
fi
echo "running: $cmd"
eval $cmd




