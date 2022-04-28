#!/bin/sh

cd $datadir/$dirversion/future_release

mkdir fasta
cd fasta

ln -s ../flat/Pfam-A.fasta
#ln -s ../flat/Pfam-B.fasta
ln -s ../flat/pfamseq

cd ..
mkdir hmm
cd hmm

ln -s ../flat/Pfam-A.hmm
#ln -s ../flat/Pfam-B.hmm
ln -s ../flat/Pfam-A.hmm.dat
#ln -s ../flat/Pfam-B.hmm.dat

. /local/env/envhmmer-3.2.1.sh

for file in `find $datadir/$dirversion/future_release/hmm/Pfam*hmm`
do
        hmmpress $file
done
