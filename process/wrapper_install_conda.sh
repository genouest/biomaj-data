#!/bin/bash
#
# Do not forget your package_to_install_list.txt (with one package name per line)
# Do not forget the python script conda_install_multi.py
#conda.name=conda
#conda.type=install
#conda.exe=wrapper_install_conda.sh
#conda.args=blast $processdir/packageblast.txt $processdir
#conda.cluster=false

args=$*

python $processdir/conda_install_multi.py $args

