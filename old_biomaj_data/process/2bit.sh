#!/bin/bash

# Script for Biomaj PostProcess
# author : Anthony Bretaudeau
# date   : 18/05/2015

if (test $# -ne 2) then
    echo "arguments:" 1>&2
    echo "1: input files" 1>&2
    echo "2: write index data to files with this dir/basename" 1>&2
    echo "2: output format (default=2bit) [OPTIONAL]" 1>&2
    echo "2: types (type1,type2,...) [OPTIONAL]" 1>&2
    echo "2: tags  (key:value,key:value,...) [OPTIONAL]" 1>&2
    exit -1
fi

# Create destination dir
echo "$2" | grep '/$' # Does it end with a trailing slash?
hastrailing=$?
if ( test $hastrailing -ne 0 ) then
    outputPath="$2"
else
    outputPath="$2/2bit-index" # There is a trailing slash, give some default prefix for index files names
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

# prepare list of input fasta files
listFile="";

for expression in $1
do
    # the basename can be a regex
    lsFile=`ls $datadir/$dirversion/future_release/$expression`;
    if ( test $? -ne 0 ) then
        echo "No input file found in dir `pwd`." 1>&2 ;
        exit 1
    fi
    for f in $lsFile
    do
        if (test -z "$listFile") then
            listFile=$f;
        else
            listFile=$f" "$listFile;
        fi
    done
done

echo "Input sequence file list: $listFile";

if (test -z "$listFile") then
    echo "No input file found." 1>&2 ;
    exit 1
fi

echo "Launching 2bit index [faToTwoBit $listFile $outputPathAbs]";

# Execute 2bit
faToTwoBit "$listFile" "$outputPathAbs";

buildResult=$?
if ( test $buildResult -ne 0 ) then
    echo "2bit index failed with status $buildResult" 1>&2 ;
    exit 1
fi


# Add generated files to biomaj postprocess dependance
echo "Generated files:";
for ff in `ls ${outputPathAbs}*`
do
    echo $PP_DEPENDENCE$PWD/$ff;
done


format="2bit"
types=""
tags=""
if [ "$4" != "" ]
then
  format=$4
fi
if [ "$5" != "" ]
then
  types=$5
fi
if [ "$6" != "" ]
then
  tags=$6
fi



echo "##BIOMAJ#$format#$types#$tags#$outputPath"

