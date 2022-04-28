#!/bin/bash

mkdir -p /tmp/uniprot
/home/symbiose/biomaj/conf-biomaj/process/migale/build_emboss.pl  $@

mv /tmp/uniprot/* /db/uniprot/future_release/emboss/
