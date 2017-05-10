#!/usr/bin/perl

use strict;

$| = 1;

# PARAMETERS

my $inDir = '05_inputLinks';

# EXECUTION

opendir DOT, $inDir or die("Can't open $inDir for scanning.\n");

my @files = map { "$inDir/$_" } sort { $a cmp $b } grep { /strip$/ } readdir DOT;

closedir DOT;

foreach my $file ( @files ) {
   
   $file =~ /input_(\d+)\.fa\.strip/;

   my $indexString = $1;

   my $targetFile = "$inDir/targetIDs_$indexString.txt";

   system("grep -h '>' $file | perl -p -i -e 's/^>//' | perl -p -i -e 's/\\/\\d+\$//' > $targetFile");

   if ( not -e $targetFile ) {
      
      print "$$SAMPLEID$$.zz22_get_read_IDs.pl failed.\n";

      exit(1);
   }
}

print "$$SAMPLEID$$.zz22_get_read_IDs.pl completed successfully.\n";

exit(0);

