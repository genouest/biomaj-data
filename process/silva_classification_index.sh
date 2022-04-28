#!/bin/bash

# MB, 17/12/12
# Workflow for SILVA database new release second post-process. For each domain and both of the three, the mothur command 'classify.seqs' is run with a fake almost empty fasta file in order to make indexes. They are stored in the directory 'index_classify'. Those indexes will be reused each time 'classify.seqs' will be called.

. /local/env/envmothur.sh

set -e

workdir=$datadir/$dirversion/future_release
cd $workdir

# Index directory creation
if [ ! -e $workdir/index_classify ]; then
	mkdir $workdir/index_classify
elif [ "$(ls -A $workdir/index_classify)" ]; then
	rm $workdir/index_classify/*
fi

# Fake file creation
if [ ! -e fic.fasta ]; then
	echo ">Seq1" > fic.fasta
else
	echo "Exiting because a file 'fic.fasta' already exists in the directory."
	exit 1
fi

# Mothur 'classify.seqs' command execution for each domain file
for file in $workdir/fasta/*
do
	domain=$(basename $file .fasta)
	mothur "#classify.seqs(fasta=fic.fasta,template=$workdir/fasta/$domain.fasta,taxonomy=$workdir/taxonomy/$domain.tax,cutoff=80)"
	mv $workdir/fasta/*8mer $workdir/taxonomy/*8mer* $workdir/taxonomy/*tree* $workdir/index_classify
done

# Fasta and taxonomy files copy in index_classify and rights management
cp $workdir/fasta/* $workdir/taxonomy/* $workdir/index_classify
chmod 646 $workdir/index_classify/*
chmod 777 $workdir/index_classify

# Directory cleaning
rm *wang* mothur.*.logfile fic.fasta
