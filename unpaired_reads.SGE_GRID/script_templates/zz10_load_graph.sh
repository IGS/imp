#!/bin/sh

workDir=02_workDir

partitionDir=03_partitionedReads

($$SUPPORT_SCRIPT_PREFIX$$/load-graph.py -k 32 -N 4 -x 8e9 $workDir/yy06_part2 $partitionDir/yy05_partition_1_groups.finalGroup.fa \
   && echo "$$SAMPLEID$$.zz10_load_graph.sh completed successfully.") || echo "$$SAMPLEID$$.zz10_load_graph.sh failed."
