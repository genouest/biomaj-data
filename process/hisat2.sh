#!/bin/bash



# How to call it in a bank.properties file ? 
#
# hisat2.name=hisat2
# hisat2.desc=Build hisat2 index
# hisat2.type=index
# hisat2.exe=star.sh
# hisat2.args="fasta/*.fasta" "hisat2/all.star name_index"
# hisat2.cluster=false


if (test $# -ne 3) then
    echo "arguments:" 1>&2
    echo "1: input files" 1>&2
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
    outputPath="$2/hitsat2-index" # There is a trailing slash, give some default prefix for index files names
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

# Execute hitsat2 index



hisat2-build $listFile $3
