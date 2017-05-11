#!/bin/sh

readDir=00_reads

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/normalize-by-median.py \
   -k 20 -C 5 -x 4e9 -R $workDir/yy02_pass2.report \
   $readDir/$$SAMPLEID$$.fastq.keep.abundfilt.below \
   && mv *keep $readDir \
   && echo "$$SAMPLEID$$.zz03_second_normalize_by_median.sh completed successfully.") || echo "$$SAMPLEID$$.zz03_second_normalize_by_median.sh failed."
