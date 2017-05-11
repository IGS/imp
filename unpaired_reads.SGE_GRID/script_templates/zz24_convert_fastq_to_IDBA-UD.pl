#!/usr/bin/perl

use strict;

$| = 1;

# PARAMETERS

my $logDir = "$$LOG_DIR$$";

my $converter = '$$SUPPORT_SCRIPT_PREFIX$$/../third_party/fq2fa';

my $linkDir = '05_inputLinks';

my $subprocMem = '1G';

# EXECUTION

opendir DOT, $linkDir or die("Can't open $linkDir for scanning.\n");

my @inputFiles = sort { $a cmp $b } grep { /^input_.*\.fa\.strip$/ } readdir DOT;

closedir DOT;

my $failed = 0;

foreach my $inFile ( @inputFiles ) {
   
   my $partitionID = $inFile;

   $partitionID =~ s/^.*_(\S+)\.fa.strip$/$1/;

   my $outFile = $inFile;

   $outFile =~ s/^(\S+)(_$partitionID).*$/$1$2\.IDBA-UD.final.fna/;

   # You MUST use the --filter option here, or the assembly will be total turtle poop.

   my $command = "( $converter --filter $linkDir/$inFile $linkDir/$outFile && echo FASTQ conversion completed successfully. ) || echo FASTQ conversion failed.";

   chomp( my $result = system($command) );

   if ( $result =~ /failed/ ) {
      
      $failed = 1;
   }
}

if ( not $failed ) {
   
   print "$$SAMPLEID$$.zz24_convert_fastq_to_IDBA-UD.pl completed successfully.\n";

} else {
   
   print "$$SAMPLEID$$.zz24_convert_fastq_to_IDBA-UD.pl failed.\n";
}


