#!/usr/bin/perl

use strict;

$| = 1;

# PARAMETERS

my $firstPartitionSetDir = "03_partitionedReads";

my $linkDir = "05_inputLinks";

my $secondPartitionSetDir = "04_finalGroupPartition_files";

# EXECUTION

opendir DOT, $firstPartitionSetDir or die("Can't open $firstPartitionSetDir for scanning.\n");

my @firstPartFiles = sort { $a cmp $b } map { "$firstPartitionSetDir/$_" } grep { /^yy04_partition_1_groups.group\d+\.fa$/ } readdir DOT;

closedir DOT;

opendir DOT, $secondPartitionSetDir or die("Can't open $secondPartitionSetDir for scanning.\n");

my @secondPartFiles = sort { $a cmp $b } map { "$secondPartitionSetDir/$_" } grep { /^yy07_part2_filtered.group\d+\.fa$/ } readdir DOT;

closedir DOT;

my @finalFileSet = ( @firstPartFiles, @secondPartFiles );

my $counter = 0;

foreach my $file ( @finalFileSet ) {
   
   my $printCounter = sprintf("%04d", $counter);
   
   my $target = "$linkDir/input_$printCounter.fa";

   system("ln -sf ../$file $target");

   if ( not -l $target ) {
      
      print "$$SAMPLEID$$.zz20_input_linker.pl failed to create link \"$target\".  Aborting.\n";

      exit(1);
   }

   $counter++;
}

print "$$SAMPLEID$$.zz20_input_linker.pl completed successfully.\n";

exit(0);


