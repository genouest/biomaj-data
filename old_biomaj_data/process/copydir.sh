# ! /bin/bash

# Copy a directory 


if (test $# -ne 2) then
        echo "arguments:" 1>&2;
        echo "1: input directory" 1>&2;
        echo "2: output directory" 1>&2;
        exit -1;
fi

workdir=$datadir/$dirversion/future_release/

cd $workdir;

if ( ! test -e $1 ) then
       echo "$1 does not exist." 1>&2;
       exit 1;
fi

if ( test -e $2 ) then
       echo "$2  exist." 1>&2;
       exit 1;
fi

mkdir -p $2;

cp -rf $1/* $2/;

if ( test $? -ne 0 ) then
     exit 1
fi





