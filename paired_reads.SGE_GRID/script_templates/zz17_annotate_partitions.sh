#!/bin/sh

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/annotate-partitions.py $workDir/yy07_part2_filtered \
   $workDir/yy05_partition_1_groups.finalGroup.fa.stopfilt \
   && mv *finalGroup.fa.stopfilt.part $workDir \
   && echo "$$SAMPLEID$$.zz17_annotate_partitions.sh completed successfully.") || echo "$$SAMPLEID$$.zz17_annotate_partitions.sh failed."

