# author : ofilangi
# date   : 19/06/2007
#
# create a link to ARG1 with the name ARG2 (create subdirectory if necessary)
#
# ARGS   :
#           1) file to link (ex:flat/myfile.fasta)
#           2) name links   (ex:fasta/myfile.fasta)
# 
#

if (test $# -ne 2) then
        echo "arguments:" 1>&2;
        echo "1: file to link (ex:flat/myfile.fasta)" 1>&2;
        echo "2: link name    (ex:fasta/myfile.fasta)" 1>&2;
        exit -1
fi

workdir=$datadir/$dirversion/future_release
dirtocreate=`dirname $workdir/$2`;

if ( ! test -e $dirtocreate ) then
       mkdir -p $dirtocreate; 
fi

if ( test $? -ne 0 ) then
        echo "Cannot create $dirtocreate." 1>&2 ;
        exit 1
fi

if (test -e $workdir/$2 ) then
	rm -f $workdir/$2;
fi

back="";
dir=`dirname $2`;
OLDIFS=$IFS;
IFS="/";
for i in $dir
do
	back="../"$back;
done
IFS=$OLDIFS;

cd $dirtocreate;
name=`basename $2`;
rm -f $name;
echo "ln -s $back$1 $name";
ln -s $back$1 $name;
if ( test $? -ne 0 ) then
        echo "Cannot create link." 1>&2 ;
        exit 1
else
	echo $PP_DEPENDENCE$dirtocreate"/"$name;
fi

