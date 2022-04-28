# !/bin/bash


if (test $# -ne 1) then
        echo "argument:" 1>&2
        echo "1: link name to apply on directory 'flat' " 1>&2
        exit -1
fi

workdir=$datadir/$dirversion/future_release;

if ( test -e $workdir/$1 ) then
        rm $workdir/$1
fi

back="";
OLDIFS=$IFS;
IFS="/";
i=0;
for t in $1
do
    myarray[$i]=$t;
    if ( test $i -ne 0 ) then
     back="../"$back;
    fi
    let "i = $i+1";
done
IFS=$OLDIFS;

if ( test $i -eq 0 ) then
	echo "Erreur script (argument vide)" 1>&2
        exit -1
fi
a=0;
cd $workdir;
while [ $i -ne 1 ]
do
    echo "create ${myarray[$a]}...";
    rm -rf ${myarray[$a]};
    mkdir ${myarray[$a]};
    cd ${myarray[$a]};
    echo `pwd`;
    let "a = $a+1";
    let "i = $i-1";
done

rm -f `basename $1`;

echo "workdir:`pwd`";
echo "ln -s "$back"flat `basename $1`";
ln -s "$back"flat `basename $1`;

if ( test $i -eq 0 ) then
        echo "Error with command link!" 1>&2
        exit -1
fi



