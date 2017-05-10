#!/bin/sh

readDir=00_reads

workDir=02_workDir

partitionDir=03_partitionedReads

($$SUPPORT_SCRIPT_PREFIX$$/annotate-partitions.py $workDir/yy03_part1 $readDir/*.fastq.keep.abundfilt.below.keep && \
   mv *.fastq.keep.abundfilt.below.keep.part $partitionDir \
   && echo "$$SAMPLEID$$.zz07_annotate_partitions.sh completed successfully.") || echo "$$SAMPLEID$$.zz07_annotate_partitions.sh failed."
