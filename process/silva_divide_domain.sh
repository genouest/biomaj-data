#!/bin/bash

# MB, 12/10/12
# Workflow for SILVA database new release post-process. A tax and a fasta file are produced for bacteria, archaea, eukaryotas and both of the three. Each RNA file is transformed in DNA through a perl script then simplified and cleaned with mothur commands.

. /local/env/envmothur.sh
. /local/env/envperl.sh
workdir=$datadir/$dirversion/future_release
if [ ! -e $workdir/fasta ]; then
	mkdir $workdir/fasta
fi
if [ ! -e $workdir/taxonomy ]; then
	mkdir $workdir/taxonomy
fi
cd $workdir/fasta

set -e

# Transforming RNA to DNA with rna2dna.pl
perl /opt/biomaj/biomaj-process/silva/rna2dna.pl $workdir/flat/*.fasta > silva.dna.fasta

# Splitting the SILVA file to get the 4 file pairs with tax_sorter.pl
perl /opt/biomaj/biomaj-process/silva/tax_sorter.pl silva.dna.fasta silva_Bacteria.tax silva_Archaea.tax silva_Eukaryota.tax > silva_Bact_Arch_Euk.tax

for file in *.tax
do
	# Getting dataset thanks to the ID list with get.seqs
	mothur "#get.seqs(accnos=${file},fasta=silva.dna.fasta)" > /dev/null
	mv silva.dna.pick.fasta ${file}.dna.pick.fasta

	# Simplifying dataset with unique.seqs
	mothur "#unique.seqs(fasta=${file}.dna.pick.fasta)" > /dev/null

	# Removing sequences with at least a 7-bases homopolymer and/or 2 ambiguous bases with screen.seqs
	mothur "#screen.seqs(fasta=${file}.dna.pick.unique.fasta,maxhomop=7,maxambig=1)" > /dev/null

	# Creating a file listing the sequences to remove from the tax file
	grep ',' ${file}.dna.pick.names | cut -d, --complement -f1 | sed 's/,/\n/g' > ${file}.dna.pick.bad.accnos
	cat ${file}.dna.pick.bad.accnos ${file}.dna.pick.unique.bad.accnos > ${file}.toremove

	# Removing sequences from the tax file with remove.seqs
	mothur "#remove.seqs(accnos=${file}.toremove,taxonomy=${file})" > /dev/null
done

# Cleaning
rename .pick.tax .tax *
rename .tax.dna.pick.unique.good.fasta .fasta *
rm -v silva_*.tax.* *.dna.fasta mothur.*logfile
mv *.tax ../taxonomy
