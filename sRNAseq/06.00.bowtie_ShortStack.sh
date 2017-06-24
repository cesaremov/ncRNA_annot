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
while [[ ! -e $bit/Genome/log.txt || `find $inPath -name "*$inPatt" | wc -l` -ne `find $inPath -name "*log.txt" | wc -l` || `find $inPath -name "*log.txt" | wc -l` -lt $numFastq ]]; do
  
   echo -ne "\rPreproc not finished, waiting..."
   sleep 1

done

# Setting up base name
base="${base//./_}"

# Genomes path
genome="$bit/Genome"

# Process parameters
nodes=1
ppn=6
mem="20G"

# BowtieShorStack options
k="500"
ShortStackLine="ShortStack --bowtie_cores $ppn --nostitch --mismatches 2 --mmap u --bowtie_m $k --ranmax $k --show_secondaries"

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

   # Bowtie
   echo "Mapping"
   cmd0="rm -rf $outPath/$base; $ShortStackLine --readfile $fqFile --genomefile $idxFile.fa --outdir $outPath/$base --align_only && echo 'OK' > $outPath/$base/$base.log.txt"
   if [[ $mode == "local" ]]; then   
      cmd=$cmd0
   elif [[ $mode == "cluster" ]]; then
      cmd="echo 'cd \$PBS_O_WORKDIR; module load ShortStack; module load bowtie/1.1.0; module load samtools/1.3.1; module load Vienna/2.2.5; $cmd0' | qsub -V -N bowtieSS -l nodes=$nodes:ppn=$ppn,mem=$mem,vmem=$mem"
   fi
   echo "running: $cmd"
   eval "date; $cmd"
         
 done


