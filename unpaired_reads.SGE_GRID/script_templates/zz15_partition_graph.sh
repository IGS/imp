#!/bin/sh

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/partition-graph.py --threads 4 $workDir/yy07_part2_filtered \
   && echo "$$SAMPLEID$$.zz15_partition_graph.sh completed successfully.") || echo "$$SAMPLEID$$.zz15_partition_graph.sh failed."
