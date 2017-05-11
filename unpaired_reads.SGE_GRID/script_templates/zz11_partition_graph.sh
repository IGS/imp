#!/bin/sh

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/partition-graph.py --threads 4 $workDir/yy06_part2 \
   && echo "$$SAMPLEID$$.zz11_partition_graph.sh completed successfully.") || echo "$$SAMPLEID$$.zz11_partition_graph.sh failed."
