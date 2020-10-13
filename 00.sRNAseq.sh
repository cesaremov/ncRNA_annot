#/bin.bash

usage(){
   echo "Usage: $0 -b/--base --fastqPath -M/--mature -a/--adapter -t/--tabu -l/--lower -u/--upper --dicermin --dicermax --mincov --pad --mode"
   echo "All arguments are mandatory"
   echo "	-b/--base	indexbasename"
   echo "	--fastqPath	path to fastq files"
   echo "	-M/--mature	miRNA mature sequences fasta file"
   echo "	-a/--adapter	3pa sequence adapter"
   echo "	-t/--tabu	5pa sequence"
   echo "	-l/--lower	require read length <= <int>"
   echo "	-u/--upper	require read length >= <int>"
   echo "	--dicermin:	dicer min"
   echo "	--dicermax: 	dicer max"
   echo "	--mincov:	minimum aligments"
   echo "	--pad:		padding between clusters"
   echo "       --mode		mode to process [local/cluster]"
   echo "	-h/--help 	print this usage message"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 24 ]]; then
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
        -b | --base )		base=$2
				shift;;
        --fastqPath )           fastqPath=$2
                                shift;;
        -M | --mature )         mature=$2
                                shift;;
        -a | --adapter )        adapter=$2
                                shift;;
        -t | --tabu )           tabu=$2
                                shift;;
        -l | --lower )          lower=$2
                                shift;;
        -u | --upper )           upper=$2
                                shift;;
	--dicermin )		dicermin=$2
				shift;;
	--dicermax )		dicermax=$2
				shift;;
	--mincov )		mincov=$2
				shift;;
	--pad )			pad=$2
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

# Links to files (no dots in linknames)
echo "Setting up fastq file"
cmd="01.rename_link_files.sh -i $fastqPath"
echo "Running: $cmd"
eval "date; $cmd"

# FastQC quality analysis
echo "FastQC analysis"
cmd="02.fastqc.sh -m $mode"
echo "Running: $cmd"
eval "date; $cmd"

# Reaper reads
echo "Reaper reads"
cmd="03.reaper.sh -a $adapter -t $tabu -m $mode"
echo "Running: $cmd"
eval "date; $cmd"

# Tally sequences
echo "Tally sequences" 
cmd="04.tally.sh -l $lower -u $upper -m $mode"
echo "Running: $cmd"
eval "date; $cmd"

# Filter out reads by length
echo "Filtering by length"
cmd="05.pullseq.sh -l $lower -u $upper -m $mode"
echo "Running: $cmd"
eval "date; $cmd"

# Align to genome (ShortStack bowtie alignment)
echo "Align to genome"
cmd="06.00.bowtie_ShortStack.sh -b $base -m $mode"
echo "Running: $cmd"
eval "date; $cmd"

# Filter out bowtie results
echo "Filtering alignemt results"
cmd="06.01.filter_bowtie.sh -m $mode"
echo "Running: $cmd"
eval "date; $cmd"

# Gather filtered bowtie results
echo "Gather alignment results"
cmd="06.02.gatherAllBam.sh -m $mode"
echo "Running: $cmd"
eval "date; $cmd"

# ShortStack analysis
echo "ShortStack"
cmd="06.03.shorstack.sh -b $base --dicermin $dicermin --dicermax $dicermax --mincov $mincov --pad $pad -m $mode"
echo "Running: $cmd"
eval "date; $cmd"

# miRDeep2 analysis
echo "miRDeep2"
cmd="07.miRDeep2.sh -b $base -M $mature --mincov $mincov -m $mode"
echo "Running: $cmd"
eval "date; $cmd"


