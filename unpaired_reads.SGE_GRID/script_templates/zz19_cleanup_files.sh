#!/bin/sh

workDir=02_workDir

partitionDir=03_partitionedReads

finalPartitionFileDir=04_finalGroupPartition_files

(mv $workDir/*merged $partitionDir && \
   mv $workDir/yy05* $workDir/yy06* $workDir/yy07* $finalPartitionFileDir \
   && echo "$$SAMPLEID$$.zz19_cleanup_files.sh completed successfully.") || echo "$$SAMPLEID$$.zz19_cleanup_files.sh failed."
