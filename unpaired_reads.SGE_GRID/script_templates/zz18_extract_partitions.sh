#!/bin/sh

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/extract-partitions.py $workDir/yy07_part2_filtered \
   $workDir/yy05_partition_1_groups.finalGroup.fa.stopfilt.part \
   && echo "$$SAMPLEID$$.zz18_extract_partitions.sh completed successfully.") || echo "$$SAMPLEID$$.zz18_extract_partitions.sh failed."
