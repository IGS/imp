#!/bin/sh

workDir=02_workDir

partitionDir=03_partitionedReads

($$SUPPORT_SCRIPT_PREFIX$$/filter-stoptags.py $workDir/yy06_part2.stoptags \
   $partitionDir/yy05_partition_1_groups.finalGroup.fa \
   && mv *.finalGroup.fa.stopfilt $workDir \
   && echo "$$SAMPLEID$$.zz13_filter_stoptags.sh completed successfully.") || echo "$$SAMPLEID$$.zz13_filter_stoptags.sh failed."
