#! /bin/bash

filename=$1
K=$2
assemblyDir=$3

BASE=`basename $filename`

if [ \! -f $filename.strip \]; then
   strip-partition.py $filename > $filename.strip
fi

echo running velveth && \
velveth $assemblyDir/$BASE.ass.$K.oases $K -fasta -short ${filename}.strip && \
echo running velvetg && \
velvetg $assemblyDir/$BASE.ass.$K.oases -read_trkg yes  && \
echo running oases && \
oases $assemblyDir/$BASE.ass.$K.oases
