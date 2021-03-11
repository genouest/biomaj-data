# ! /bin/bash
# Script for Biomaj PostProcess
# author : ofilangi
# date   : 19/06/2007
#
# create a fasta directory and compute fasta file from genbank format file
#
# ARGS   :
#           1) regular expression for file to apply gb2fasta
#           2) extension of file (example : .seq)
#           3) option gb2fasta
#
#
# Usage: gb2fasta [-h] [-c case] [-g] [-s] [-l dbPrefix] [dataFileName ...]
#
#-h      This message
#-c      Speicfiy the case of the output sequence.
#        Valid values: u, l, o. Default: o
#-g      Ignored, for compatability with WU-BLAST gb2fasta
#-s      Simple fasta headers ID and DE only
#-l      Specifiy database label
#
# Default input from STDIN unless files specified. To explictly specify STDIN
# to be used for input use '-' as filename


if (test $# -ne 4) then
	echo "arguments:" 1>&2;
	echo "1: files to apply gb2fasta" 1>&2;
	echo "2: extension from file genbank (".seq",".gb","")" 1>&2;
	echo "3: label (gb,est)" 1>&2;
	echo "4: directory for the file generated." 1<&2;
	exit -1
fi

workdir=$datadir/$dirversion/future_release
echo "apply gb2fasta from $workdir/flat to $workdir/$4";

if (! test -e $workdir/$4 ) then
	mkdir -p $workdir/$4
fi 

cd $workdir/flat

for i in `ls $1 | grep -v gbcon`
do    
       bank=`basename $i $2`;
       
       if (test $? -ne 0) then
             echo "basename generate an error!" 1>&2 ;
             exit 1;
       fi

       if ( test -z "$bank") then
             echo "$0 can't find basename from $i with extension:$2" 1>&2 ;
             exit 1;     
       fi

       res=$workdir/$4/$bank.fasta;
       if (! test -e $res) 
         then
           echo "/softs/local/bin/gb2fasta -l $3 $i > $res";
           /softs/local/bin/gb2fasta -l $3 $i > $res;
           
            if (test $? -ne 0) then
             echo "gb2fasta return an error !" 1>&2 ;
             rm -f $res;
             exit 1;
           fi

	   echo $PP_DEPENDENCE$res;
         else
           echo "$res exist!"
        fi
       # gb2fasta -l $3 $i > $workdir/fasta/$bank
       # echo $PP_DEPENDENCE$workdir/fasta/$bank
done

