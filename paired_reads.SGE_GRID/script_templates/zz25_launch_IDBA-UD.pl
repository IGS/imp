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

my $headerFixer = '$$SUPPORT_SCRIPT_PREFIX$$/uniquifyFastaHeaders.specifyMaxHeaderLength.pl';

my $maxHeaderLength = 50;

my $assembler = '$$SUPPORT_SCRIPT_PREFIX$$/../third_party/idba_ud';

my $logDir = "$$LOG_DIR$$";

my $linkDir = '05_inputLinks';

my $asmRoot = '06_assembly';

my $scriptDir = 'zz26_IDBA_launch_scripts';

# EXECUTION

# Delete the old assembly.

system("rm -f $$SAMPLEID$$__FINAL_ASSEMBLY.fna");

system("mkdir -p $asmRoot");

system("mkdir -p $scriptDir");

opendir DOT, $linkDir or die("Can't open $linkDir for scanning.\n");

my @inFiles = sort { $a cmp $b } grep { /IDBA\-UD\.final\.fna$/ } readdir DOT;

closedir DOT;

my @launchers = ();

foreach my $inFile ( @inFiles ) {
   
   $inFile =~ /^.*_([^_]+)\.IDBA/;

   my $partitionID = $1;

   my $asmDir = "$asmRoot/idba-ud_assembly_$partitionID";

   system("mkdir -p $asmDir");

   my $launcher = "$scriptDir/run_IDBA.partition_$partitionID.sh";

   push @launchers, $launcher;

   open LAUNCH, ">$launcher" or die("Can't open $launcher for writing.\n");

   print LAUNCH "#!/bin/sh\n\n";

   my $command = "\"(rm -rf $asmDir && $assembler --mink 20 --maxk 80 --step 10 --num_threads 10 --min_contig 100 -r $linkDir/$inFile -o $asmDir && echo Partition $partitionID assembly completed successfully.) || echo Partition $partitionID assembly failed.\"";

   print LAUNCH "qsub -sync y -V -b y -P $$PROJECT_CODE$$ -q threaded.q -pe thread 12 -l mem_free=$memReq$memSuffix -N mga26_$$SAMPLEID$$\.$partitionID \\\n";
   
   print LAUNCH "   -e $logDir \\\n -o $logDir -cwd \\\n";
   
   print LAUNCH "   $command\n\n";

   close LAUNCH;

   system("chmod 755 $launcher");

   system("qsub -q all.q -l mem_free=1G -V -b y -P $$PROJECT_CODE$$ -N mga26.ctl.$$SAMPLEID$$_$partitionID -e $$LOG_DIR$$ -o $$LOG_DIR$$ -cwd $launcher");
}

# Start checking to see whether or not the jobs have completed.
# If they haven't, loop once a minute and check again until they're
# all done or one fails.

my $allFinished = 0;

while ( not $allFinished ) {
   
   $allFinished = &checkDone(\@inFiles);

   if ( not $allFinished ) {
      
      system("sleep 60");
   }
}

my $assemblyFile = "$$SAMPLEID$$__FINAL_ASSEMBLY.fna";

system("cat $asmRoot/idba-ud_assembly_*/contig.fa > $assemblyFile");

system("$headerFixer $assemblyFile $maxHeaderLength");

my $uniqueHeaderAssemblyFile = $assemblyFile;

$uniqueHeaderAssemblyFile =~ s/\.fna$/.unique_header_IDs.fna/;

system("mv $uniqueHeaderAssemblyFile $assemblyFile");

print "$$SAMPLEID$$.IDBA_assemblies completed successfully.\n";

exit(0);

# Check for completion reports written by the launchers, and see if
# they're all successfully completed.  If any reports a failure, halt
# the current script and print a failure report.

sub checkDone {
   
   my $arrayRef = shift;

   my @files = @$arrayRef;

   foreach my $file ( @files ) {
      
      $file =~ /_(\d+)\.IDBA-UD\.final\.fna$/;

      my $partitionID = $1;

      chomp( my $lastErrorFile = `/bin/ls -altrF $logDir/mga26_$$SAMPLEID$$\.$partitionID\.o* 2>&1 | tail -q -n1` );

      $lastErrorFile =~ s/^.*\s+//;

      if ( not -e $lastErrorFile ) {
         
         # Job hasn't started yet.

         print "No assembly log yet for $partitionID; waiting.\n";

         return 0;

      } else {
         
         # Job has begun.

         my $statusLine = `tail -q -n 1 $lastErrorFile`;

         if ( $statusLine =~ /failed/ and not $fixedFiles->{$partitionID} ) {
            
            # Job failed: try to recover.

            # If contig-80.fa for this partition was begun,

            if ( -e "$asmRoot/idba-ud_assembly_$partitionID/contig-80.fa" ) {
               
               # If the assembly got as far as /finishing/ contig-80.fa (i.e. began writing contig.fa),

               if ( -e "$asmRoot/idba-ud_assembly_$partitionID/contig.fa" ) {
                  
                  # Filter contig-80.fa to produce a sane contig.fa.

                  print "Fixing contig output for partition $partitionID...";

                  open IN, "<$asmRoot/idba-ud_assembly_$partitionID/contig-80.fa" or die("Can't open $asmRoot/idba-ud_assembly_$partitionID/contig-80.fa for reading.\n");

                  open OUT, ">$asmRoot/idba-ud_assembly_$partitionID/contig.fa" or die("Can't open $asmRoot/idba-ud_assembly_$partitionID/contig.fa for writing.\n");

                  my $recording = 0;

                  while ( my $line = <IN> ) {
                     
                     if ( $line =~ /^>.*\sread_count_(\d+)/ ) {
                        
                        my $readCount = $1;

                        $recording = 0;

                        if ( $readCount >= $contig80readCovThreshold ) {
                           
                           print OUT $line;

                           $recording = 1;
                        }

                     } elsif ( $recording ) {
                        
                        print OUT $line;
                     }
                  }

                  close OUT;

                  close IN;

                  print "done.\n";

                  $fixedFiles->{$partitionID} = 1;
               }
            }

            if ( not $fixedFiles->{$partitionID} ) {
               
               print "$$SAMPLEID$$.zz26_IDBA_assembly_$partitionID failed.\n";

               exit(1);
            }

         } elsif ( $statusLine !~ /completed\s+successfully/ ) {
            
            # Job still running.

            print "Job still running for $partitionID; waiting.\n";

            return 0;
         }
      }
   }

   # All jobs completed successfully.

   return 1;
}


