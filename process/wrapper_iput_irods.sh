#!/bin/bash

# Do not forget BioMAJ version with irods and to install python-irodsclient and ro work with python3
#BLOCKS=BLOCK1,BLOCK2
#BLOCK1.db.post.process=META0
#META0=PROC0
#PROC0.name=irods_iput
#PROC0.desc=iput file on iRODS
#PROC0.type=file tranfert
## Command to execute, in process.dir or path
#PROC0.exe=iput_irods.py
## Arguments
#PROC0.args=%(irods.user)s %(irods.password)s %(server)s %(irods.port)s %(irods.protocol)s %(irods.zone)s %(remote.dir)s "flat/*"

#variables
irods_user=$1
shift
irods_password=$1
shift
server=$1
shift
irods_port=$1
shift
irods_protocol=$1
shift
irods_zone=$1
shift
remote_dir=$1
shift
expression=$@
workdir=$datadir/$dirversion/future_release/flat # real wordir during BioMAJ process

#echo "PROC0.args=%(irods.user)s %(irods.password)s %(server)s %(irods.port)s %(irods.protocol)s %(irods.zone)s %(remote.dir)s "
#echo '$irods_user $irods_password $server $irods_ports $irods_protocol $irods_zone $remote_dir'
#echo $irods_user $irods_password $server $irods_ports $irods_protocol $irods_zone $remote_dir
echo "expression"
echo $expression
#echo "$datadir/$dirversion/future_release/flat/alu.a"


for expression in $expression
do
   lsFile=`ls $datadir/$dirversion/$localrelease/$expression`;
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


echo "$listFile"
echo $server

for file in $listFile
do 
  python3 $processdir/iput_irods.py -f $file -p $remote_dir -u $irods_user -a $irods_password -r $irods_port -z $irods_zone -s $server -c $dirversion/$localrelease

done 

