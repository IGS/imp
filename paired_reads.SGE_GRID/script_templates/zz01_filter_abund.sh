#!/bin/sh

readDir=00_reads

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/filter-abund.py \
   $workDir/yy00_pass1.kh \
   $readDir/$$SAMPLEID$$.mate_1.fastq.keep \
   $readDir/$$SAMPLEID$$.mate_2.fastq.keep && \
mv *abundfilt $readDir \
&& echo "$$SAMPLEID$$.zz01_filter_abund.sh completed successfully.") || echo "$$SAMPLEID$$.zz01_filter_abund.sh failed."
