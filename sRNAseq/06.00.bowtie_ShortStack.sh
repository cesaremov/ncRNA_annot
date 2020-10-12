#!/bin/bash

usage(){
   echo "Usage: $0 -b/--base -m/--mode"
   echo "	-b/--base:		index basename"
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
bit="./ncRNA"
inPath="$bit/pullseq"
outPath="$bit/bowtie_ShortStack"

mkdir -p  $outPath

# Patts
inPatt=".fq.gz"

# Check preproc
numFastq=`find $bit/Raw/ -name "*fastq.gz" | wc -l`
while [[ ! -e $bit/Genome/log.txt || `find $inPath -name "*$inPatt" | wc -l` -ne `find $inPath -name "*log" | wc -l` || `find $inPath -name "*log" | wc -l` -lt $numFastq ]]; do
  
   echo -ne "\rPreproc pullseq not finished, waiting..."
   sleep 1

done

# Setting up base name
base="${base//./_}"

# Genomes path
genome="$bit/Genome"

# Cluster params
J=$(basename $0 .sh)
p="computes_standard"
N=1
n=32
qos="ipicyt"

# BowtieShorStack options
k="500"
ShortStackLine="ShortStack --bowtie_cores $n --nostitch --mismatches 2 --mmap u --bowtie_m $k --ranmax $k --show_secondaries"

# Genome info
idxFile="$genome/$base"

# Files to process
#inFiles=`find -E $inPath -iregex ".+fq.gz"`
inFiles=`find  $inPath -name "*$inPatt"`
echo $inFiles
for fqFile in $inFiles; do

   echo "$fqFile"

   #name=`echo $fqFile | perl -pe "s/.+\/|\.$inExt$//g"`
   base="`basename $fqFile`"
   base="${base/$inPatt/}"

   # Get logFile
   logFile="$outPath/$base.bowtie_ss.log"

   if [[ -f $logFile ]]; then
      echo -e "$logFile already exists, continue...\n"
      continue
   fi   

   # Bowtie
   echo "Mapping"
   cmd0="rm -rf $outPath/$base; $ShortStackLine --readfile $fqFile --genomefile $idxFile.fa --outdir $outPath/$base --align_only && echo 'OK' > $logFile"
   if [[ $mode == "local" ]]; then   
      cmd=$cmd0
   elif [[ $mode == "cluster" ]]; then
      cmd="echo -e '#!/bin/bash \n $cmd0' | \
            sbatch -J $J -p $p -N $N --ntasks-per-node=$n --qos=$qos -o $logFile && touch $logFile"
   fi

   # Run
   echo -e "Running: $cmd\n"
   eval "date; $cmd"
         
 done


