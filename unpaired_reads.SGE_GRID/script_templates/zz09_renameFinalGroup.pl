#!/usr/bin/perl

use strict;

$| = 1;

# PARAMETERS

my $partitionDir = '03_partitionedReads';

# EXECUTION

opendir DOT, "$partitionDir" or die("Can't open $partitionDir for scanning.\n");

my @files = map { "$partitionDir/$_" } grep { /^yy04_partition_1_groups\.group\d+\.fa$/ } readdir DOT;

closedir DOT;

my $finalFile = ( sort { $b cmp $a } @files )[0];

my $targetFile = $finalFile;

$targetFile =~ s/\/([^\/]+)$/\//;

$targetFile .= 'yy05_partition_1_groups.finalGroup.fa';

system("rm -f $targetFile");

system("mv $finalFile $targetFile");

if ( -e $targetFile ) {
   
   print "$$SAMPLEID$$.zz09_renameFinalGroup.pl completed successfully.\n";

   exit(0);

} else {
   
   print "$$SAMPLEID$$.zz09_renameFinalGroup.pl failed.\n";

   exit(1);
}

