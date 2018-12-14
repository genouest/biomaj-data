#!/bin/bash



# How to call it in a bank.properties file ? 
#
# star.name=star
# star.desc=Build star index
# star.type=index
# star.exe=star.sh
# star.args="fasta/*.fasta" "star/all.star name_index"
# star.cluster=false


if (test $# -ne 2) then
    echo "arguments:" 1>&2
    echo "1: input file" 1>&2
    echo "2: write index data to files with this dir/basename" 1>&2
    echo "3: output name" 1>&2
    exit -1
fi

# Create destination dir
echo "$2" | grep '/$' # Does it end with a trailing slash?
hastrailing=$?
if ( test $hastrailing -ne 0 ) then
    outputPath="$2"
else
    outputPath="$2/picard-dict" # There is a trailing slash, give some default prefix for index files names
fi

relWorkDir=`dirname "$outputPath"`

workdir="$datadir/$dirversion/future_release/$relWorkDir"
outputPathAbs="$datadir/$dirversion/future_release/$outputPath"

rm -rf $workdir;
mkdir -p $workdir ;

if ( test $? -ne 0 ) then
    echo "Cannot create $workdir." 1>&2 ;
    exit 1;
fi



# Execute picard index

picard CreateSequenceDictionary R=$1.fa O=$3.dict
