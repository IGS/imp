#!/bin/sh

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/partition-graph.py --threads 4 -s 1e5 $workDir/yy03_part1 \
   && echo "$$SAMPLEID$$.zz05_partition_graph.sh completed successfully.") || echo "$$SAMPLEID$$.zz05_partition_graph.sh failed."
