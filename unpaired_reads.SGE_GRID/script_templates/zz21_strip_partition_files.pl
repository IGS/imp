#!/usr/bin/perl

use strict;

$| = 1;

# PARAMETERS

my $linkDir = '05_inputLinks';

# EXECUTION

opendir DOT, $linkDir or die("Can't open $linkDir for scanning.\n");

my @files = sort { $a cmp $b } map { "$linkDir/$_" } grep { /^input_\d+\.fa$/ } readdir DOT;

closedir DOT;

foreach my $file ( @files ) {
   
   my $command = "$$SUPPORT_SCRIPT_PREFIX$$/strip-partition.py $file > $file.strip";

   system($command);

   if ( not -e "$file.strip" ) {
      
      print "$$SAMPLEID$$.zz21_strip_partition_files.pl failed to create file \"$file.strip\".  Aborting.\n";

      exit(1);
   }
}

print "$$SAMPLEID$$.zz21_strip_partition_files.pl completed successfully.\n";

