#!/bin/sh

partitionDir=03_partitionedReads

($$SUPPORT_SCRIPT_PREFIX$$/extract-partitions.py $partitionDir/yy04_partition_1_groups $partitionDir/*.fastq.keep.abundfilt.below.keep.part \
   && echo "$$SAMPLEID$$.zz08_extract_partitions.sh completed successfully.") || echo "$$SAMPLEID$$.zz08_extract_partitions.sh failed."
