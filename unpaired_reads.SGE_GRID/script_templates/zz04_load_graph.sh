#!/bin/sh

readDir=00_reads

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/load-graph.py \
   -k 32 -N 4 -x 8e9 $workDir/yy03_part1 \
   $readDir/$$SAMPLEID$$.fastq.keep.abundfilt.below.keep \
   && echo "$$SAMPLEID$$.zz04_load_graph.sh completed successfully.") || echo "$$SAMPLEID$$.zz04_load_graph.sh failed."
