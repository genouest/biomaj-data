# !/bin/bash
# Applique un formatdb sur plusieurs repertoire

# Arguments:
#            1 -   chemin de l'ensemble des repertoires/fichiers a appliquer le formatdb
#            2 -   nombre de repertoire a ne pas prendre en compte pour la creation
#            3 -   repertoire destination

#etc.....        
#
if (test $# -ne 4) then
        echo "arguments:" 1>&2
        echo "1: regular expression for directories to apply a link (ex:fasta/CHR_*)" 1>&2;
        echo "2: int    (ex: '1' remove fasta dir)" 1>&2;
        echo "3: result directory    (ex: 'blast')" 1>&2;
        echo "4: generic name for bdd(ex: 'fungi')" 1>&2;
        exit 1;
fi



workdir=$datadir/$dirversion/future_release;

cd $workdir;
#Pour chaque fichier
nbFile=0;

for fileSeq in $1
do
echo "-------------------";
echo "Traitement $fileSeq";

 let "nbFile = $nbFile+1";
 OLDIFS=$IFS;
 IFS="/";
 a=0;
 nameResult="";
 for name in $fileSeq
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

blastName=$nameResult;
resultdir=`dirname $3/$blastName`;
echo "in file   :$fileSeq";
echo "result dir:$resultdir";
val1=`dirname $blastName`;
bdd=`basename $val1`;

echo "bdd blast :$bdd";

$PATH_PROCESS_BIOMAJ/formatdb.sh $fileSeq $resultdir "-p F -o T" "$4_$bdd";
if ( test $? -ne 0 ) then
    echo "Error with formatdb.sh." 1>&2 ;
    exit 1
fi
done


