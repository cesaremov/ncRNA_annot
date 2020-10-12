#/bin/bash

usage(){
   echo "Usage: $0 -b/--base -M/--mature --mincov -m/--mode"
   echo "	-b/--base:	index basename"
   echo "	-M/--mature:	miRNA mature sequences"
   echo "	--mincov:	minimum aligments"
   echo "	-m/--mode:	mode to process"
   echo "	-h/--help 	print this usage message"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 8 ]]; then
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
        -b | --base )		base=$2
				shift;;
	-M | --mature )		mature0=$2
				shift;;
	--mincov )		mincov=$2
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

# Exit if no defined model
#if [[ $mode != "local" || $mode != "cluster" ]]; then
#   usage
#   exit
#fi

# Paths
bit="./ncRNA"
inPath="$bit/tally"
outPath="$bit/miRDeep2"

#rm -r $outPath
mkdir -p $outPath

# Patts
patt=".fa.gz"

# Cheack tally preproc
while [[ ! `find $inPath -name "*$patt" | wc -l` == `find $inPath -name "*log" | wc -l` ]]; do

   echo -ne "\rTally has not finished, waiting..."
   sleep 3

done

# Setting up base name
base="${base//./_}"

# Genome
genome="$bit/Genome/$base"

# Mature sequences
mature=$(cd "$(dirname $mature0)"; pwd)/$(basename "$mature0")
echo $mature0
echo $mature
sed 's/ /_/g' < $mature | sed 's/U/T/g' > $outPath/$mature0.miRDeep2

# All fasta file
allBase="$outPath/all_Tally"

# Gather fasta files
echo "Gathering files"
cat $inPath/*$patt | gzip -dc - > $allBase.0.fa

# Subtitute dots by underscores and clean
sed 's/\./_/g' $allBase.0.fa > $allBase.fa
rm $allBase.0.fa


# Cluster params
J=$(basename $0 .sh)
p="computes_standard"
N=1
n=32
qos="ipicyt"

# Change to miRDeep2 pathh
cd $outPath


# Get logFile
logFile="miRDeep.log"

if [[ -f $logFile ]]; then
   echo -e "$logFile already exists, exiting...\n"
   exit
fi   


# Map to the genome
echo "Mapping"
grepPatt='"provisional id|yes\t|no\t"'
cmd0="mapper.pl ../../$allBase.fa -c -j -l 18 -m -o $n -p ../../$genome -q -s ../../${allBase}_collapsed.fa -t ../../$allBase.arf && miRDeep2.pl ../../${allBase}_collapsed.fa ../../$genome.fa ../../$allBase.arf ./$mature0.miRDeep2 none none -a $mincov -g 500 -v;
      cat result*.csv | grep -E $grepPatt > Results.txt;
      cp result*.bed miRDeep.bed" 
if [[ $mode == "local" ]]; then
   cmd=$cmd0 
elif [[ $mode == "cluster" ]]; then
   cmd="echo -e '#!/bin/bash \n $cmd0' | \
        sbatch -J $J -p $p -N $N -n $n --qos=$qos -o $logFile && touch $logFile"

else
   usage
fi

# Run
echo "Running: $cmd"
eval "date && $cmd"

#cat result*.csv | grep -E 'provisional id|yes\t|no\t' > ./Results.txt





