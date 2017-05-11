#!/bin/sh

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/load-graph.py -k 32 -N 4 -x 8e9 $workDir/yy07_part2_filtered $workDir/yy05_partition_1_groups.finalGroup.fa.stopfilt \
   && echo "$$SAMPLEID$$.zz14_load_graph.sh completed successfully.") || echo "$$SAMPLEID$$.zz14_load_graph.sh failed."
