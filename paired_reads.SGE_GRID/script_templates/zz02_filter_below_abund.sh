#!/bin/sh

readDir=00_reads

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/filter-below-abund.py \
   $workDir/yy00_pass1.kh \
   $readDir/$$SAMPLEID$$.mate_1.fastq.keep.abundfilt \
   $readDir/$$SAMPLEID$$.mate_2.fastq.keep.abundfilt \
   && mv *below $readDir \
   && echo "$$SAMPLEID$$.zz02_filter_below_abund.sh completed successfully.") || echo "$$SAMPLEID$$.zz02_filter_below_abund.sh failed."
