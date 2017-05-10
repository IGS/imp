#!/bin/sh

readDir=00_reads

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/normalize-by-median.py -k 20 -C 20 -x 4e9 -N 4 \
   -s $workDir/yy00_pass1.kh \
   -R $workDir/yy01_pass1.report \
   $readDir/$$SAMPLEID$$.mate_1.fastq \
   $readDir/$$SAMPLEID$$.mate_2.fastq \
   && \
   mv *keep $readDir \
   && \
   echo "$$SAMPLEID$$.zz00_normalize_by_median.sh completed successfully.") || echo "$$SAMPLEID$$.zz00_normalize_by_median.sh failed."
