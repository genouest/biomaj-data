#!/bin/bash

. /db/biomaj/biomaj-process/biomaj2galaxy/v2.0/bm2g_venv/bin/activate

set -u # stop if a variable is not initialized
set -e # stop in case of error

export LC_ALL=en_US.utf8
export LANG=en_US.utf8

export BM2G_GLOBAL_CONFIG_PATH=/db/biomaj/biomaj-process/biomaj2galaxy/v2.0/bm2g.yml

echo "Updating yourgalaxyserver Galaxy instance..."
biomaj2galaxy -i yourgalaxyserver "$@"
echo "Done"
