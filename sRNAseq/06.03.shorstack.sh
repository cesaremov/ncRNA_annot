#!/bin/bash

usage(){
   echo "Usage: $0 -b/--base --dicermin --dicermax --mincov --pad -m/--mode"
   echo "	-b/--base	index basename"
   echo "	--dicermin:	dicer min"
   echo "	--dicermax: 	dicer max"
   echo "	--mincov:	minimum aligments"
   echo "	--pad:		padding between clusters"
   echo "	-m/--mode:	mode to process"
   echo "	-h/--help 	print this usage message"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 12 ]]; then
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
        -b | --base )		base=$2
				shift;;
	--dicermin )		dicermin=$2
				shift;;
	--dicermax )		dicermax=$2
				shift;;
	--mincov )		mincov=$2
				shift;;
	--pad )			pad=$2
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
inPathGenomes="$bit/Genome"
inPathAlign="$bit/gatherAllBam"
outPath="$bit/shortstack"

rm -rf $outPath

# Patts
inPatt=".bam"

# Cheack gathering preproc
while [[ ! -e $inPathAlign/gatherAllBam.log ]]; do

   echo -ne "\rGathering has not finished, waiting..."
   sleep 3
   
done

# Setting up base name
base="${base//./_}"

# Cluster params
J=$(basename $0 .sh)
p="computes_standard"
N=1
n=32
qos="ipicyt"

# ShortStack line
ssLine="ShortStack --genomefile $inPathGenomes/$base.fa --dicermin $dicermin --dicermax $dicermax --mincov $mincov --pad $pad"

# Files to process
inFiles=`ls $inPathAlign/all$inPatt`

for bamFile in $inFiles; do

   echo $bamFile

   # Get logFile
   logFile="Log.txt" #"$outPath/$(basename $bamFile .bam).log"

   if [[ -f $logFile ]]; then
      echo -e "$logFile already exists, continue...\n"
      continue
   fi  

   # ShortStack processing
   echo "ShortStack"
   cmd0="$ssLine --bamfile $bamFile --outdir $outPath"  # && touch $logFile"
   if [[ $mode == "local" ]]; then
      cmd=$cmd0 
   elif [[ $mode == "cluster" ]]; then
      cmd="echo -e '#!/bin/bash \n $cmd0' | \
            sbatch -J $J -p $p -N $N --ntasks-per-node=$n --qos=$qos" # -o $logFile" #&& touch $logFile" 
   fi 
   
   # Run
   echo -e "Running: $cmd\n"
   eval "date && $cmd"

done



