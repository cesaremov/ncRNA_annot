#!/bin/bash

usage(){
   echo "Usage: $0 -i/--inPath"
   echo "	-i/--inPath:	path to fastq files (fastq.gz)"
   echo "	-h/--help 	print this usage message"
   exit 1
}

# Check number of arguments
if [[ $1 == "" ]] || [[ $# -ne 2 ]]; then
   usage
fi

# Define arguments
while [[ "$1" != "" ]]; do
    case $1 in
        -i | --inPath )		inPath0=$2
				shift;;
        -h | --help )           usage
                                exit;;
        * )                     usage
                                exit 1
    esac
    shift
done

# Paths
abPath="`dirname $inPath0 | cd | pwd`"
inPath=$inPath0   #"$abPath/`dirname $inPath0`"
bit="./ncRNA"
outPath="$bit/Raw"

mkdir -p $outPath

# Files to re-name
inFiles=`find $inPath/ -name '*fastq.gz'` # a-iregex ".+fastq$|.+fq$|.+sanfastq$|.+fastq.gz$|.+fq.gz$|.+sanfastq.gz$"`
echo $inFiles
for inFile in $inFiles; do 
 
   echo $inFile

   # . to _ 
   base=`basename ${inFile//./_}`

   case "$base" in
	*_fastq )	base=${base/_fastq/.fastq};;
	*_fq )		base=${base/_fq/.fq};;
	*_sanfastq )	base=${base/_sanfastq/.sanfastq};; 
	*_fastq_gz )	base=${base/_fastq_gz/.fastq.gz};;
        *_fq_gz )	base=${base/_fq_gz/.fq.gz};;
        *_sanfastq_gz )	base=${base/_sanfastq_gz/.sanfastq.gz};;
	* ) 		usage
			exit 1;;
   esac

   # Link
   echo "Linking"
   cmd="ln -sf $abPath/$inFile $outPath/$base"
   echo "running: $cmd"
   eval $cmd

done

