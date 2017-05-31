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

my @inputFiles = sort { $a cmp $b } grep { /\d+\.mate_1\.final\.fastq$/ } readdir DOT;

closedir DOT;

foreach my $mateOne ( @inputFiles ) {
   
   $mateOne =~ /^.*_(\d+)\.mate_1\.final\.fastq$/;

   my $partitionID = $1;

   my $mateTwo = $mateOne;

   $mateTwo =~ s/\.mate_1\./\.mate_2\./;

   my $outFile = $mateOne;

   $outFile =~ s/^(\S+)\.mate_1\.final\.fastq$/$1\.IDBA-UD.final.fna/;

   # You MUST use the --filter option here, or the assembly will be total turtle poop.

   my $command = "\"($converter --merge --filter $linkDir/$mateOne $linkDir/$mateTwo $linkDir/$outFile && echo FASTQ conversion completed successfully.) || echo FASTQ conversion failed.\"";

   system("qsub -V -sync y -b y -P $$PROJECT_CODE$$ -q all.q -l mem_free=$subprocMem -N mga24_convertFasta\_$$SAMPLEID$$_$partitionID \\\n   -e $logDir \\\n   -o $logDir -cwd \\\n   $command\n\n");

   chomp( my $lastOutFile = `/bin/ls -tr $logDir/mga24_convertFasta\_$$SAMPLEID$$_$partitionID.o* | tail -q -n1` );

   if ( not -e $lastOutFile ) {
      
      die("FASTQ conversion failed.\n");

   } else {
      
      chomp( my $statusLine = `tail -q -n1 $lastOutFile` );

      if ( $statusLine =~ /failed/ ) {
         
         die("FASTQ conversion failed.\n");
      }
   }
}

print "FASTQ conversion completed successfully.\n";


