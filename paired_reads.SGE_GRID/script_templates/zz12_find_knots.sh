#!/bin/sh

workDir=02_workDir

($$SUPPORT_SCRIPT_PREFIX$$/find-knots.py $workDir/yy06_part2 \
   && echo "$$SAMPLEID$$.zz12_find_knots.sh completed successfully.") || echo "$$SAMPLEID$$.zz12_find_knots.sh failed."
