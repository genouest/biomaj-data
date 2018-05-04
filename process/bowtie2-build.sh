#!/bin/bash

# Script for Biomaj PostProcess
# author : Anthony Bretaudeau
# date   : 06/12/2013
#
# How to call it in a bank.properties file ? (ex: Bos_taurus.properties)

# bowtie2.name=bowtie2
# bowtie2.desc=Build bowtie2 index
# bowtie2.type=index
# bowtie2.exe=bowtie2-build.sh
# bowtie2.args="fasta/all.fasta" "bowtie2/all"
# bowtie2.cluster=false



if (test $# -ne 2) then
    echo "arguments:" 1>&2
    echo "1: input files" 1>&2
    echo "2: write .bt2 data to files with this dir/basename" 1>&2
    echo "2: output format (default=bowtie2) [OPTIONAL]" 1>&2
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
    outputPath="$2/bowtie2-index" # There is a trailing slash, give some default prefix for index files names
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
            listFile=$f","$listFile;
        fi
    done
done

echo "Input sequence file list: $listFile";

if (test -z "$listFile") then
    echo "No input file found." 1>&2 ;
    exit 1
fi

echo "Launching bowtie2-build [bowtie-build2 $listFile $outputPathAbs]";

# Execute bowtie2-build
bowtie2-build "$listFile" "$outputPathAbs";

buildResult=$?
if ( test $buildResult -ne 0 ) then
    echo "Bowtie2-build failed with status $buildResult" 1>&2 ;
    exit 1
fi


# Add generated files to biomaj postprocess dependance
echo "Generated files:";
for ff in `ls ${outputPathAbs}*`
do
    echo $PP_DEPENDENCE$PWD/$ff;
done

format="bowtie2"
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
