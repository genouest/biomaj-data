#!/bin/bash

workdir=$datadir/$dirversion/$localrelease/
mkdir $workdir/diamond
echo "Formatting to diamond at $workdir/diamond"
cd  $workdir/diamond

diamond $@
