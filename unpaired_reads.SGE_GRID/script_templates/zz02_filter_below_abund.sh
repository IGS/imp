#!/bin/sh

readDir=00_reads

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/filter-below-abund.py \
   $workDir/yy00_pass1.kh \
   $readDir/$$SAMPLEID$$.fastq.keep.abundfilt \
   && mv *below $readDir \
   && echo "$$SAMPLEID$$.zz02_filter_below_abund.sh completed successfully.") || echo "$$SAMPLEID$$.zz02_filter_below_abund.sh failed."
