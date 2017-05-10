#! /bin/bash

filename=$1
K=$2
assemblyDir=$3
scriptDir=$4

BASE=`basename $filename`

echo running oases && \
oases $assemblyDir/$BASE.asm.$K.oases && \
echo done -- removing LastGraph and Graph2 and Roadmaps files... && \
rm $assemblyDir/$BASE.asm.$K.oases/LastGraph && \
rm $assemblyDir/$BASE.asm.$K.oases/Graph2 && \
rm $assemblyDir/$BASE.asm.$K.oases/Roadmaps && \
echo done
