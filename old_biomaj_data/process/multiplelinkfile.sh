#!/bin/bash
# author : ofilangi
# date   : 27/11/2007
#
# create a link for the plateforme ouest-genopole for a bank with multiple directories
# verify the structuration of the new link :
#         [format]/[section1]/[section2]/file
#

# ARGS   :
#           1) regular expression for directories to apply a link
#           2) nb directories to remove
#           3) result directory

if (test $# -ne 3) then
        echo "arguments:" 1>&2
        echo "1: regular expression for directories to apply a link (ex:flat/CHR_*)" 1>&2;
        echo "2: int    (ex: '1' remove flat dir)" 1>&2;
        echo "3: result directory    (ex: 'fasta')" 1>&2;
        exit 1;
fi


workdir=$datadir/$dirversion/future_release;

cd $workdir;
#Pour chaque fichier 
nbFile=0;
for file in `ls $1`
do
 let "nbFile = $nbFile+1";
 OLDIFS=$IFS;
 IFS="/";
 a=0;
 nameResult="";
 for name in $file
 do
    if [ $a -ge $2 ]
      then
          if [ "$nameResult" != "" ]
           then
            nameResult=$nameResult/$name;
           else
            nameResult=$name;
          fi          
      fi
    let "a = $a+1";
 done
IFS=$OLDIFS;
 
 linkACreer=$nameResult;
 #Test si c est un fichier
 if [ -e $linkACreer ]; then
	echo "[$linkACreer] Ce fichier existe deja! impossible de creer ce lien !" 1>&2;
	exit 2;
 else
        $PATH_PROCESS_BIOMAJ/linkfile.sh $file $3/$linkACreer;
        if ( test $? -ne 0 ) then
               echo "Cannot create link." 1>&2 ;
               exit 1
        fi

 fi
done

if [ $nbFile -eq 0 ]; then
	echo "No files find !";
	exit 2;
else
	echo "$nbFile are been linked !";
fi


