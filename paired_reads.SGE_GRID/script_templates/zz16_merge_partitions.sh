#!/bin/sh

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/merge-partitions.py $workDir/yy07_part2_filtered \
   && echo "$$SAMPLEID$$.zz16_merge_partitions.sh completed successfully.") || echo "$$SAMPLEID$$.zz16_merge_partitions.sh failed."
