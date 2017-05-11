#!/bin/sh

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/merge-partitions.py $workDir/yy03_part1 \
   && echo "$$SAMPLEID$$.zz06_merge_partitions.sh completed successfully.") || echo "$$SAMPLEID$$.zz06_merge_partitions.sh failed."
