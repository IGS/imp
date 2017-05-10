#!/usr/bin/perl

use strict;

$| = 1;

# ARGUMENTS

my $expansionFactor = shift;

$expansionFactor =~ s/X$//;

my $testFileString = shift;

chomp( my $flatFileList = `/bin/ls $testFileString`);

my @testFiles = split(/\n/, $flatFileList);

my $maxBytes = 0;

foreach my $testFile ( @testFiles ) {
   
   my $fileBytes = -s $testFile;

   if ( $maxBytes < $fileBytes ) {
      
      $maxBytes = $fileBytes;
   }
}

if ( $maxBytes == 0 ) {
   
   die("FATAL: $0: Could not locate one or more target files: \"$testFileString\"; aborting.\n");
}

my $maxMB = $maxBytes / 1024;

$maxMB /= 1024;

$maxMB *= $expansionFactor;

my $memReq = int($maxMB) + 1;

my $memSuffix = 'M';

if ( $memReq > 1000 ) {
   
   $memReq /= 1024;

   $memReq = int($memReq) + 1;

   $memSuffix = 'G';
}

# PARAMETERS

my $readDir = '00_reads';

my $linkDir = '05_inputLinks';

my $launcher = 'zz23a_retrieve_pairs__launcher.sh';

# EXECUTION

opendir DOT, $linkDir or die("Can't open $linkDir for scanning.\n");

my @files = map { "$linkDir/$_" } sort { $a cmp $b } grep { /^targetIDs_\d+\.txt$/ } readdir DOT;

closedir DOT;

open LAUNCH, ">$launcher" or die("Can't open $launcher for writing.\n");

print LAUNCH "#!/bin/sh\n\n";

my $first = 1;

foreach my $file ( @files ) {
   
   if ( $first ) {
      
      # Skip the first set, temporarily.  (See below.)

      $first = 0;

      next;

   } else {
      
      $file =~ /targetIDs_(\d+)\.txt/;

      my $indexString = $1;

      my $sourceFile = "$readDir/$$SAMPLEID$$.mate_1.fastq";

      my $targetFile = "$linkDir/$$SAMPLEID$$_$indexString\.mate_1.final.fastq";

      my $command = "$$SUPPORT_SCRIPT_PREFIX$$/preserveGivenReadsInFastq.pl $file $sourceFile $targetFile";

      print LAUNCH "qsub -V -b y -P $$PROJECT_CODE$$ -q all.q -l mem_free=$memReq$memSuffix -N mga23a_$indexString\.mate_1.$$SAMPLEID$$ \\\n   -e $$LOG_DIR$$ \\\n   -o $$LOG_DIR$$ -cwd \\\n   $command\n\n";

      $sourceFile = "$readDir/$$SAMPLEID$$.mate_2.fastq";

      $targetFile = "$linkDir/$$SAMPLEID$$_$indexString\.mate_2.final.fastq";

      $command = "$$SUPPORT_SCRIPT_PREFIX$$/preserveGivenReadsInFastq.pl $file $sourceFile $targetFile";

      print LAUNCH "qsub -V -b y -P $$PROJECT_CODE$$ -q all.q -l mem_free=$memReq$memSuffix -N mga23a_$indexString\.mate_2.$$SAMPLEID$$ \\\n   -e $$LOG_DIR$$ \\\n   -o $$LOG_DIR$$ -cwd \\\n   $command\n\n";
   }
}

# Now do the first set.  It'll be at least as big as any of the others,
# so since that's true and we're running it last, there's a good chance
# that when the sync on the second-mate parse releases, the others will
# be done already.  If they aren't, we're dropping tokens with
# preserveGivenReadsInFastq.pl, so we'll be able to detect that and wait
# as needed.

my $file = $files[0];

$file =~ /targetIDs_(\d+)\.txt/;

my $indexString = $1;

my $sourceFile = "$readDir/$$SAMPLEID$$.mate_1.fastq";

my $targetFile = "$linkDir/$$SAMPLEID$$_$indexString\.mate_1.final.fastq";

my $command = "$$SUPPORT_SCRIPT_PREFIX$$/preserveGivenReadsInFastq.pl $file $sourceFile $targetFile";

print LAUNCH "qsub -V -b y -P $$PROJECT_CODE$$ -q all.q -l mem_free=15G -N mga23a_$indexString\.mate_1.$$SAMPLEID$$ \\\n   -e $$LOG_DIR$$ \\\n   -o $$LOG_DIR$$ -cwd \\\n   $command\n\n";

$sourceFile = "$readDir/$$SAMPLEID$$\.mate_2.fastq";

$targetFile = "$linkDir/$$SAMPLEID$$_$indexString\.mate_2.final.fastq";

$command = "$$SUPPORT_SCRIPT_PREFIX$$/preserveGivenReadsInFastq.pl $file $sourceFile $targetFile";

print LAUNCH "qsub -V -sync y -b y -P $$PROJECT_CODE$$ -q all.q -l mem_free=15G -N mga23a_$indexString\.mate_2.$$SAMPLEID$$ \\\n   -e $$LOG_DIR$$ \\\n   -o $$LOG_DIR$$ -cwd \\\n   $command\n\n";

close LAUNCH;

system("chmod 755 $launcher");

# Now the launcher's built, and the very last command will
# sync until complete.  Invoke the launcher with its own
# sync.

if ( system("qsub -V -sync y -b y -P $$PROJECT_CODE$$ -q all.q -l mem_free=10G -N mga23a.$$SAMPLEID$$ \\\n   -e $$LOG_DIR$$ \\\n   -o $$LOG_DIR$$ -cwd \\\n   $launcher") != 0 ) {
   
   print "$$SAMPLEID$$.zz23_retrieve_pairs.pl failed.\n";

   exit(1);
}

# Okay; the very last parse (of intentionally maximal size) has
# finished.  Now check to see whether or not the rest have all
# completed.  If they haven't, loop once a minute and check again
# until they're done or they've barfed.

my $allFinished = 0;

while ( not $allFinished ) {
   
   $allFinished = &checkDone(\@files);

   if ( not $allFinished ) {
      
      system("sleep 60");
   }
}

# Clean up the tokens.

print "$$SAMPLEID$$.zz23_retrieve_pairs.pl completed successfully.\n";

exit(0);

# Check for the tokens dropped by preserveGivenReadsInFastq.pl, and
# see if they're all present.  If a failure token is present, stop
# the current script and print a failure report.

sub checkDone {
   
   my $arrayRef = shift;

   my @idFiles = @$arrayRef;

   foreach my $file ( @idFiles ) {
      
      $file =~ /targetIDs_(\d+)\.txt/;

      my $indexString = $1;

      my $failureFile = "$linkDir/$$SAMPLEID$$_$indexString\.mate_1.final.fastq.failed";

      if ( -e $failureFile ) {
         
         print "$$SAMPLEID$$.zz23_retrieve_pairs.pl failed.\n";

         exit(1);
      }

      $failureFile    = "$linkDir/$$SAMPLEID$$_$indexString\.mate_2.final.fastq.failed";

      if ( -e $failureFile ) {
         
         print "$$SAMPLEID$$.zz23_retrieve_pairs.pl failed.\n";

         exit(1);
      }
   }

   foreach my $file ( @idFiles ) {
      
      $file =~ /targetIDs_(\d+)\.txt/;

      my $indexString = $1;

      my $targetFile = "$linkDir/$$SAMPLEID$$_$indexString\.mate_1.final.fastq.complete";

      if ( not -e $targetFile ) {
         
         return 0;
      }

      $targetFile    = "$linkDir/$$SAMPLEID$$_$indexString\.mate_2.final.fastq.complete";

      if ( not -e $targetFile ) {
         
         return 0;
      }
   }

   return 1;
}

