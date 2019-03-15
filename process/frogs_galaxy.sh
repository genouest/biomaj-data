#!/bin/bash

WORKDIR=$datadir/$dirversion/$localrelease/

B2G_OPTS=""

cd "$WORKDIR/flat/HVL/ITS/"

for i in *; do
    for j in $i/*fasta; do
        [ -f "$j" ] || continue
        B2G_OPTS="$B2G_OPTS HVL_db:"`pwd`/$j":"`basename $j .fasta`
    done
done

cd "$WORKDIR"

cd "$WORKDIR/flat/contaminants/"

for i in *fa; do
    [ -f "$i" ] || continue
    B2G_OPTS="$B2G_OPTS phiX_db:"`pwd`/$i":"`basename $i .fa`
done

cd "$WORKDIR"

cd "$WORKDIR/flat/assignation/"

for i in *; do
    for j in $i/*/*/*fasta; do
        [ -f "$j" ] || continue
        B2G_OPTS="$B2G_OPTS frogs_db:"`pwd`/$j":"`basename $j .fasta`
    done
    for j in $i/*/*fasta; do
        [ -f "$j" ] || continue
        B2G_OPTS="$B2G_OPTS frogs_db:"`pwd`/$j":"`basename $j .fasta`
    done
done

cd "$WORKDIR"

echo "Running /db/biomaj/biomaj-process/biomaj2galaxy/v2.0/bm2g.sh add -d "${localrelease}" $B2G_OPTS"

/db/biomaj/biomaj-process/biomaj2galaxy/v2.0/bm2g.sh add -d "${localrelease}" $B2G_OPTS
