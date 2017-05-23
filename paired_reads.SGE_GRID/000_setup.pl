#!/usr/bin/perl

use strict;

$| = 1;

################################################################################
# PARAMETERS
################################################################################

# ------------------------------------------------------------------------------
# [0] Reference data locations:
# ------------------------------------------------------------------------------

chomp( my $pwd = `pwd` );

# IMA installation root directory.

my $INSTALL_ROOT = '/path/to/your/install_dir';

my $SGEpeArg = '-pe thread';

my $SGEdefaultQueue = 'all.q';

my $SGEthreadedQueue = 'threaded.q';

# Directory containing finished scripts which will be invoked
# during execution of the assembly pipeline.

my $supportScriptPrefix = "$INSTALL_ROOT/paired_reads.SGE_GRID/support_scripts";

# Grid nodes to exclude during all processing.  Use of '*' wildcards to
# specify the exclusion of all nodes matching the given pattern is
# permitted.

my @excludeList = ();

# Directory containing placeholder-embedded script templates
# to be used to construct finished scripts for each sample to
# be assembled.

my $localScriptTemplateDir = "$INSTALL_ROOT/paired_reads.SGE_GRID/script_templates";

my $controlDir = '001_assembly_master_controller_scripts';

my $controlLogDir = '002_assembly_logs';

my $controlLogArchiveDir = "$controlLogDir/.partial";

my $masterScript = '003_run_assemblies.sh';

my $localResumeScript = '004_resume_pipeline.pl';

my $locFile = 'zz00_input_locations.txt';

my $pCodeFile = 'zz01_project_code.txt';

my $excludeFile = 'zz02_nodes_to_exclude.txt';

# ------------------------------------------------------------------------------
# [1] Global variables and data structures:
# ------------------------------------------------------------------------------

my $readLocs = {};

my $projectCode = '';

# Amount of memory to request for each assembly-pipeline step,
# along with notes describing direct measurements of memory consumption
# during testing.  The majority of steps use amounts of memory
# that are independent of (sequence) input size, and are thus given a
# constant amount of memory to request for all runs.
# 
# The rest of the steps depend on the amount of information contained
# in (input-sequence-size-dependent) processing files that are generated
# during pipeline operation.  In these cases, the pipeline controller is
# tasked to measure the total size of files on which memory consumption
# depends for a particular step, and then compute a memory-consumption
# request for that step based on preset expansion formulas (e.g., "3X"
# means "compute a (generously rounded) memory request size that's
# three times the combined total of the appropriate input files").

my $scriptMem = {
   
   # Used 60GB.  Memory is dependent on preset hash size.
   'zz00_normalize_by_median.sh' => '65G',
   # Used 60GB.  Memory is dependent on preset hash size.
   'zz01_filter_abund.sh' => '65G',
   # Used 60GB.  Memory is dependent on preset hash size.
   'zz02_filter_below_abund.sh' => '65G',
   # Used 60GB.  Memory is dependent on preset hash size.
   'zz03_second_normalize_by_median.sh' => '65G',
   # Used 17GB.  Memory is dependent on (a new) preset hash size.
   'zz04_load_graph.sh' => '25G',
   # Used 4.3GB.  Input hashtable was preset at 4GB.
   'zz05_partition_graph.sh' => '10G',
   # Used 4.2GB.  Input hashtable was preset at 4GB.
   'zz06_merge_partitions.sh' => '10G',
   ### Test sample: used 3.3GB for 108MB input file "yy03_part1.pmap.merged" plus "*.fastq.keep.abundfilt.below.keep" files totaling 1.1GB.
   'zz07_annotate_partitions.sh' => '4X',
   ### Test sample: used 500MB for input "*.fastq.keep.abundfilt.below.keep.part" files totaling 1.1GB.
   'zz08_extract_partitions.sh' => '1X',
   # Used 6MB.  Memory independent of input size.
   'zz09_renameFinalGroup.pl' => '100M',
   # Used 15.2GB.  Input hashtable was preset at 4GB.
   'zz10_load_graph.sh' => '40G',
   # Used 15.7GB.  Input hashtable was preset at 4GB.
   'zz11_partition_graph.sh' => '40G',
   # Used 15.9GB.  Input hashtable was preset at 4GB.
   'zz12_find_knots.sh' => '40G',
   ### Test sample: used 95MB to filter "yy05_partition_1_groups.finalGroup.fa" using a 2MB "yy06_part2.stoptags" file, the latter being the only input whose size determines memory consumption.
   'zz13_filter_stoptags.sh' => '100X',
   # Test sample: used 15.2GB.  Input hashtable preset at 4GB.
   'zz14_load_graph.sh' => '40G',
   # Test sample: used 15.7GB.  Input hashtable preset at 4GB.
   'zz15_partition_graph.sh' => '40G',
   ### Test sample: used 495MB for input ".subset.*.pmap" files totaling 48MB.
   'zz16_merge_partitions.sh' => '20X',
   ### Test sample: used 360MB.  Input ".stopfilt" and "*.pmap.merged" files totaled 145MB.
   'zz17_annotate_partitions.sh' => '5X',
   ### Test sample: used 45MB for 135MB input partition file "yy05_partition_1_groups.finalGroup.fa.stopfilt.part".
   'zz18_extract_partitions.sh' => '2X',
   # Used 4MB.  Memory independent of input size.
   'zz19_cleanup_files.sh' => '100M',
   # Used 7MB.  Memory independent of input size.
   'zz20_input_linker.pl' => '100M',
   # Used 30MB.  Memory independent of input size.
   'zz21_strip_partition_files.pl' => '500M',
   # Used 7MB.  Memory independent of input size.
   'zz22_get_read_IDs.pl' => '100M',
   ### This is a wrapper; subprocesses do the work.  Test sample: subprocs used max ~500MB each.  Input target-ID lists ranged from 2.5MB to 19MB.
   'zz23_retrieve_pairs.pl' => 'SUB40X:100M',
   ### Another wrapper.  Test sample: subprocs used max ~6MB each.  Input FASTQ files ranged from 28MB to 210MB; memory consumption should be independent of input size.
   'zz24_convert_fastq_to_IDBA-UD.pl' => '100M',
   ### Another wrapper.  Test sample: bottom-level subprocs used max 16GB (min 1.2GB) each.  Input FASTA files ranged from 28MB to 210MB.
   'zz25_launch_IDBA-UD.pl' => 'SUB100X:100M'
};

# File dependencies for memory-request computations for scripts that need them (see previous data structure).

my $scriptDeps = {
   
   'zz07_annotate_partitions.sh' => '02_workDir/yy03_part1.pmap.merged;00_reads/*.fastq.keep.abundfilt.below.keep',
   'zz08_extract_partitions.sh' => '03_partitionedReads/*.fastq.keep.abundfilt.below.keep.part',
   'zz13_filter_stoptags.sh' => '02_workDir/yy06_part2.stoptags',
   'zz16_merge_partitions.sh' => '02_workDir/yy07_part2_filtered.subset.*.pmap',
   'zz17_annotate_partitions.sh' => '02_workDir/yy07_part2_filtered.pmap.merged;02_workDir/yy05_partition_1_groups.finalGroup.fa.stopfilt',
   'zz18_extract_partitions.sh' => '02_workDir/yy05_partition_1_groups.finalGroup.fa.stopfilt.part',
   'zz23_retrieve_pairs.pl' => 'SUB:05_inputLinks/targetIDs_*.txt',
   'zz25_launch_IDBA-UD.pl' => 'SUB:05_inputLinks/*.IDBA-UD.final.fna'
};

# Thread counts for processes requiring multithreaded operation.

my $scriptThreads = {
   
   'zz05_partition_graph.sh' => 4,
   'zz11_partition_graph.sh' => 4,
   'zz15_partition_graph.sh' => 4
};

################################################################################
# EXECUTION
################################################################################

# ------------------------------------------------------------------------------
# Locate input files.
# ------------------------------------------------------------------------------

if ( -e $locFile ) {
   
   # Process the input-locations file to obtain read-file paths for each listed sample.

   open IN, "<$locFile" or die("Can't open $locFile for reading.\n");

   while ( chomp( my $line = <IN> ) ) {
      
      (my $sampleID, my $mateID, my $fileLoc) = split(/\t/, $line);

      if ( not -e $fileLoc ) {
         
         die("FATAL: Cannot find file \"$fileLoc\" (specified in $locFile).  Aborting setup.\n");
      }

      $readLocs->{$sampleID}->{$mateID} = $fileLoc;
   }

   close IN;

} else {
   
   # Give user the option to enter the data on the command line.

   &promptForReadLocs();
}

# ------------------------------------------------------------------------------
# Check data format requirements.
# ------------------------------------------------------------------------------

foreach my $sampleID ( keys %$readLocs ) {
   
   my @mateArray = sort { $a <=> $b } keys %{$readLocs->{$sampleID}};

   if ( scalar( @mateArray ) != 2 or ( $mateArray[0] != 1 or $mateArray[1] != 2 ) ) {
      
      die("FATAL: Exactly two (paired) mate-file FASTQ locations need to be specified for each sample ID, with mates labeled \"1\" and \"2\".  Please check your inputs and try again.\n");
   }
}

# ------------------------------------------------------------------------------
# Get the project code under which all grid operations will be performed.
# ------------------------------------------------------------------------------

if ( -e $pCodeFile ) {
   
   open IN, "<$pCodeFile" or die("Can't open $pCodeFile for reading.\n");

   chomp( $projectCode = <IN> );

   close IN;

} else {
   
   &promptForProjectCode();
}

# ------------------------------------------------------------------------------
# Identify grid nodes to exclude.
# ------------------------------------------------------------------------------

if ( -e $excludeFile ) {
   
   open IN, "<$excludeFile" or die("Can't open $excludeFile for reading.\n");

   while ( chomp( my $nodeID = <IN> ) ) {
      
      push @excludeList, $nodeID;
   }

   close IN;
}

# ------------------------------------------------------------------------------
# Make one directory to contain all samples' assembly-controller Perl scripts.
# ------------------------------------------------------------------------------

system("mkdir -p $controlDir");

# ------------------------------------------------------------------------------
# Make one directory to contain assembly-controller log files.
# ------------------------------------------------------------------------------

system("mkdir -p $controlLogDir");

# ------------------------------------------------------------------------------
# Create an archive trap for partially-completed assembly-controller log files.
# ------------------------------------------------------------------------------

system("mkdir -p $controlLogArchiveDir");

# ------------------------------------------------------------------------------
# Link the root-level pipeline control-modification scripts.
# ------------------------------------------------------------------------------

system("ln -sf $supportScriptPrefix/resume_pipeline.pl $localResumeScript");

################################################################################
# Make a master launch-script to run all assembly controllers for all samples.
################################################################################

open TOPLEVEL_LAUNCHER, ">$masterScript" or die("Can't open $masterScript for writing.\n");

print TOPLEVEL_LAUNCHER "#!/bin/sh\n\n";

# ------------------------------------------------------------------------------
# Configure each sample's assembly working directory, using the data from
# $locFile together with the script templates stored in $localScriptTemplateDir.
# ------------------------------------------------------------------------------

foreach my $sampleID ( sort { $a cmp $b } keys %$readLocs ) {
   
   print STDERR "Starting setup for $sampleID\.\n\n";

   print STDERR "   [--] Linking input FASTQ...";

   # ------------------------------------------------------------------------------
   # Make the directory which will store links to read files.
   # ------------------------------------------------------------------------------

   my $readBase = "$sampleID/00_reads";

   system("mkdir -p $readBase");

   # ------------------------------------------------------------------------------
   # Link the input files for $sampleID.
   # ------------------------------------------------------------------------------

   foreach my $mateID ( sort { $a cmp $b } keys %{$readLocs->{$sampleID}} ) {
      
      my $srcFile = $readLocs->{$sampleID}->{$mateID};

      system("ln -sf $srcFile $readBase/$sampleID\.mate_$mateID\.fastq");
   }

   print STDERR "done.\n";

   # ------------------------------------------------------------------------------
   # Create needed subdirectories for $sampleID's assembly.
   # ------------------------------------------------------------------------------

   print STDERR "   [--] Creating working subdirectories...";

   my $logDir = "$sampleID/01_logs";

   system("mkdir -p $logDir");

   $logDir =~ s/^$sampleID\///;

   my $workDir = "$sampleID/02_workDir";

   system("mkdir -p $workDir");

   my $partitionDir = "$sampleID/03_partitionedReads";

   system("mkdir -p $partitionDir");

   my $finalGroupDir = "$sampleID/04_finalGroupPartition_files";

   system("mkdir -p $finalGroupDir");

   my $inputLinkDir = "$sampleID/05_inputLinks";

   system("mkdir -p $inputLinkDir");

   my $asmDir = "$sampleID/06_assembly";

   system("mkdir -p $asmDir");

   print STDERR "done.\n";

   ################################################################################
   # Create the assembly-controller script for this sample and forward the
   # grid-node-exclusion list if there is one.
   ################################################################################

   my $assemblyController = "$controlDir/$sampleID\.pl";

   open ASM_CONTROLLER, ">$assemblyController" or die("Can't open $assemblyController for writing.\n");

   print ASM_CONTROLLER

qq~#!/usr/bin/perl

use strict;

\$| = 1;

my \@excludeList = ();

~;

   if ( scalar( @excludeList ) > 0 ) {
      
      foreach my $nodeID ( @excludeList ) {
         
         print ASM_CONTROLLER "push \@excludeList, '$nodeID';\n";
      }

      print ASM_CONTROLLER "\n";
   }

   ################################################################################
   # Create a line in the master launch-script to submit $sampleID's assembly-
   # controller script as a grid process.
   ################################################################################

   if ( scalar( @excludeList ) > 0 ) {
      
      print TOPLEVEL_LAUNCHER "qsub -V -b y -P $projectCode -q $SGEdefaultQueue -l mem_free=2G "
                            . "-l h='!'\"(" . join('|', @excludeList) . ")\" "
                            . "-N IMA_master_controller\.$sampleID -e $pwd/$controlLogDir -o $pwd/$controlLogDir -wd $pwd/$sampleID ../$assemblyController\n\n";

   } else {
      
      print TOPLEVEL_LAUNCHER "qsub -V -b y -P $projectCode -q $SGEdefaultQueue -l mem_free=2G "
                            . "-N IMA_master_controller\.$sampleID -e $pwd/$controlLogDir -o $pwd/$controlLogDir -wd $pwd/$sampleID ../$assemblyController\n\n";
   }

   ################################################################################
   # Configure all template-based control scripts.
   ################################################################################

   print STDERR "   [00] Customizing and copying all support scripts from reference templates...";

   my $scriptIndex = sprintf("%02d", 0);

   foreach my $scriptName ( sort keys %$scriptMem ) {
      
      my $inFile = "$localScriptTemplateDir/$scriptName";

      open IN, "<$inFile" or die("Can't open $inFile for reading.\n");

      my $outFile = "$sampleID/$scriptName";

      open OUT, ">$outFile" or die("Can't open $outFile for writing.\n");

      while ( my $line = <IN> ) {
         
         $line =~ s/\$\$SUPPORT_SCRIPT_PREFIX\$\$/$supportScriptPrefix/g;
      
         $line =~ s/\$\$SAMPLEID\$\$/$sampleID/g;

         $line =~ s/\$\$PROJECT_CODE\$\$/$projectCode/g;

         $line =~ s/\$\$LOG_DIR\$\$/$logDir/g;

         print OUT $line;
      }

      close OUT;

      close IN;

      system("chmod 755 $outFile");

      # ------------------------------------------------------------------------------
      # Wrap this script using the sample's master launch-script.
      # ------------------------------------------------------------------------------

      print ASM_CONTROLLER qq~#################################################################
#           Step $scriptIndex: $scriptName               #
#################################################################

print "RUNNING STEP $scriptIndex...\\n\\n";

~;

      my $threadString = ' ';

      if ( exists( $scriptThreads->{$scriptName} ) ) {
         
         $threadString = " $SGEpeArg $scriptThreads->{$scriptName} ";
      }

      my $memString = $scriptMem->{$scriptName};

      my $subMemString = '';

      my $subDepString = '';

      if ( $memString =~ /^SUB/ ) {
         
         my ($subMem, $mainMem) = split(/:/, $memString);

         $subMemString = $subMem;

         $subMemString =~ s/^SUB//;

         $subMemString = " $subMemString";

         # Configure (fixed) memory for wrapper script.

         $mainMem =~ /^(\d+)([^\d])$/;

         my $baseMem = $1;

         my $memSuffix = $2;

         print ASM_CONTROLLER "my \$baseMem = $baseMem;\n\nmy \$memSuffix = '$memSuffix';\n\n";

         $subDepString = $scriptDeps->{$scriptName};

         $subDepString =~ s/^SUB://;

         $subDepString =~ s/;/ /g;

         $subDepString = " '$subDepString'";

      } elsif ( $memString !~ /X$/ ) {
         
         # No subprocs to instruct; no input dependencies.

         $memString =~ /^(\d+)([^\d])$/;

         my $baseMem = $1;

         my $memSuffix = $2;
         
         print ASM_CONTROLLER "my \$baseMem = $baseMem;\n\nmy \$memSuffix = '$memSuffix';\n\n";

      } else {
         
         # No subprocs to instruct; unroll input dependency information.

         my @testFiles = split(/;/, $scriptDeps->{$scriptName});

         $memString =~ /^(\d+)X$/;

         my $expansionFactor = $1;

         print ASM_CONTROLLER "my \$baseMB = 0;\n\n";

         print ASM_CONTROLLER "chomp( my \$testFileString = \`/bin/ls " . join( " ", @testFiles ) . "\` );\n\n";

         print ASM_CONTROLLER "foreach my \$testFile ( split(\/\\n\/, \$testFileString ) ) {\n   \n";

         print ASM_CONTROLLER "   \$baseMB += -s \$testFile;\n";

         print ASM_CONTROLLER "}\n\n\$baseMB /= 1024;\n\n\$baseMB /= 1024;\n\n\$baseMB *= $expansionFactor;\n\n\$baseMB = int(\$baseMB) + 1;\n\n";

         print ASM_CONTROLLER "my \$baseMem = \$baseMB;\n\nmy \$memSuffix = 'M';\n\nif ( \$baseMem > 1000 ) {\n   \n   \$baseMem /= 1024;\n\n\   \$baseMem = int(\$baseMem) + 1;\n\n   \$memSuffix = 'G';\n}\n\n";
      }

      if ( scalar( @excludeList ) == 0 ) {
         
         if ( $threadString eq ' ' ) {
            
            print ASM_CONTROLLER "system(\"qsub -sync y -V -b y -q $SGEdefaultQueue -l mem_free=\$baseMem\$memSuffix -P $projectCode -N mga$scriptIndex.$sampleID -e $logDir -o $logDir -wd $pwd/$sampleID ./$scriptName$subMemString$subDepString\");\n\n";

         } else {
            
            print ASM_CONTROLLER "system(\"qsub -sync y -V -b y -q $SGEthreadedQueue$threadString-l mem_free=\$baseMem\$memSuffix -P $projectCode -N mga$scriptIndex.$sampleID -e $logDir -o $logDir -wd $pwd/$sampleID ./$scriptName$subMemString$subDepString\");\n\n";
         }

      } else {
         
         if ( $threadString eq ' ' ) {
            
            print ASM_CONTROLLER "system(\"qsub -sync y -V -b y -q $SGEdefaultQueue -l mem_free=\$baseMem\$memSuffix -l h='!'\\\"(\" . join('|', \@excludeList) . \")\\\" -P $projectCode -N mga$scriptIndex.$sampleID -e $logDir -o $logDir -wd $pwd/$sampleID ./$scriptName$subMemString$subDepString\");\n\n";

         } else {
            
            print ASM_CONTROLLER "system(\"qsub -sync y -V -b y -q $SGEthreadedQueue$threadString-l mem_free=\$baseMem\$memSuffix -l h='!'\\\"(\" . join('|', \@excludeList) . \")\\\" -P $projectCode -N mga$scriptIndex.$sampleID -e $logDir -o $logDir -wd $pwd/$sampleID ./$scriptName$subMemString$subDepString\");\n\n";
         }
      }

      print ASM_CONTROLLER "chomp( my \$lastErrorFile = \`/bin/ls -altrF $logDir/mga$scriptIndex.$sampleID.o* 2>&1 | tail -q -n1\` );\n\n";

      print ASM_CONTROLLER "\$lastErrorFile =~ s/^.*\\s+(\\S+)\$/\$1/;\n\n";

      print ASM_CONTROLLER "my \$success = 0;\n\n";

      print ASM_CONTROLLER "if ( -e \$lastErrorFile ) {\n\n   my \$statusLine = \`tail -q -n 1 \$lastErrorFile\`;\n\n";

      print ASM_CONTROLLER "   if ( \$statusLine =~ /completed\\s+successfully/ ) {\n      \n";

      print ASM_CONTROLLER "      print \"\\nSTEP $scriptIndex COMPLETED SUCCESSFULLY.\\n\";\n\n      \$success = 1;\n   }\n\n}\n\nif ( not \$success ) {\n   \n";

      print ASM_CONTROLLER "   print \"\\nFATAL: STEP $scriptIndex FAILED.  ABORTING ASSEMBLY PIPELINE.\\n\";\n\n   exit(1);\n}\n\n";

      $scriptIndex = sprintf("%02d", ++$scriptIndex);
   }

   print STDERR "done.\n";

   close ASM_CONTROLLER;

   system("chmod 755 $assemblyController");

   print STDERR "\nFinished processing for set $sampleID\.\n";
}

close TOPLEVEL_LAUNCHER;

system("chmod 755 $masterScript");

# SUBROUTINES

sub promptForReadLocs {
   
   print "No \"$locFile\" found; please enter sample data.\n\n";

   my $done = 0;

   while ( not $done ) {
      
      my $sampleID = '';

      while ( length($sampleID) == 0 ) {
         
         print "First sample ID (no spaces please): ";

         chomp( $sampleID = <STDIN> );

         if ( $sampleID =~ /\s/ ) {
            
            print "   ...no spaces please...\n";

            $sampleID = '';

         } elsif ( $sampleID =~ /[\/:\;\?\!\@\#\$\%\&\*\(\)\+]/ ) {
            
            print "   ...please remove all funky characters from your sample ID and try again...\n";
            
            $sampleID = '';
         }
      }

      my $mateOneLoc = '';

      while ( length($mateOneLoc) == 0 ) {
         
         print "Location of FASTQ file for $sampleID mate 1: ";

         chomp( $mateOneLoc = <STDIN> );

         if ( $mateOneLoc =~ /\s/ ) {
            
            print "   ...no spaces please...\n";

            $mateOneLoc = '';

         } elsif ( not -e $mateOneLoc ) {
            
            print "   ERROR: \"$mateOneLoc\": File not found!\n";

            $mateOneLoc = '';
         }
      }

      my $mateTwoLoc = '';

      while ( length($mateTwoLoc) == 0 ) {
         
         print "Location of FASTQ file for $sampleID mate 2: ";

         chomp( $mateTwoLoc = <STDIN> );

         if ( $mateTwoLoc =~ /\s/ ) {
            
            print "   ...no spaces please...\n";

            $mateTwoLoc = '';

         } elsif ( not -e $mateTwoLoc ) {
            
            print "   ERROR: \"$mateTwoLoc\": File not found!\n";

            $mateTwoLoc = '';
         }
      }

      $readLocs->{$sampleID}->{1} = $mateOneLoc;

      $readLocs->{$sampleID}->{2} = $mateTwoLoc;

      print STDERR "\n...saved data for $sampleID.  Got another sample to set up simultaneously? [Y\/N]: ";

      chomp( my $response = <STDIN> );
      
      if ( $response !~ /^yes$/i and $response !~ /^y$/i ) {
         
         $done = 1;
      }
   }
}

sub promptForProjectCode {
   
   print "No \"$pCodeFile\" found; please enter SGE project ID: ";

   my $pCodeVal = '';

   while ( length($pCodeVal) == 0 ) {
      
      chomp( $pCodeVal = <STDIN> );

      if ( $pCodeVal =~ /\s/ ) {
         
         print "   ...no spaces please...\n";

         $pCodeVal = '';
      }
   }

   print "Confirmed: will use SGE project code \"$pCodeVal\".\n";

   $projectCode = $pCodeVal;

   open OUT, ">$pCodeFile" or die("Can't open $pCodeFile for writing.\n");

   print OUT "$projectCode\n";

   close OUT;
}


