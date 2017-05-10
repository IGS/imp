#!/bin/sh

/usr/local/packages/sge-root/bin/lx24-amd64/qstat -xml | grep JB_name | perl -p -i -e "s/^\s*<JB_name>//" | perl -p -i -e "s/<\/JB_name>.*$//"

