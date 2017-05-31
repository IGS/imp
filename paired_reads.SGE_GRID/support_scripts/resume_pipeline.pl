#!/usr/bin/perl

use strict;

$| = 1;

# ARGUMENT

my $sampleID = shift;

$sampleID =~ s/\/+$//;

die("Usage: $0 <sample ID>\n") if ( $sampleID eq '' );

# PARAMETERS

# SGE project code.

chomp( my $projectCode = `cat zz01_project_code.txt` );

# qstat binary location.  I alias mine to a wrapper script, so this is safest for me.

my $qstat = '/usr/local/packages/sge-root/bin/lx24-amd64/qstat';

my $controlScriptDir = '001_assembly_master_controller_scripts';

my $masterControlScript = "$controlScriptDir/$sampleID.pl";

my $asmLogDir = '002_assembly_logs';

my $jobNamePrefix = 'IMA_master_controller';

# Grid nodes to exclude during all processing.  Use of '*' wildcards to
# specify the exclusion of all nodes matching the given pattern is
# permitted.

my $excludeFile = 'zz02_nodes_to_exclude.txt';

my @excludeList = ();

# EXECUTION

# Load the grid-node exclusion list, if there is one.

if ( -e $excludeFile ) {
   
   open IN, "<$excludeFile" or die("Can't open $excludeFile for reading.\n");

   while ( chomp( my $line = <IN> ) ) {
      
      push @excludeList, $line;
   }

   close IN;
}

# Make sure the pipeline isn't currently running.

chomp( my $qstatResult = `$qstat -j mgaMaster.$sampleID 2>&1` );

if ( $qstatResult !~ /do\s+not\s+exist/ ) {
   
   print "\n   FATAL: A job is already on the grid, executing the pipeline for sample $sampleID.\n";
   print   "   Its job ID is \"mgaMaster.$sampleID\"; please either kill it or allow it to complete\n";
   print   "   before running this script.\n\n";

   exit(1);
}

# Get the name of the most-recent log file for this sample's assembly pipeline.

chomp( my $lastLogFile = `/bin/ls -trF $asmLogDir/$jobNamePrefix.$sampleID.o* | tail -q -n1` );

# If it doesn't exist, something's awry.

if ( $lastLogFile eq '' ) {
   
   print "\n   FATAL: Couldn't find a log file for sample $sampleID.  Either it was deleted,\n";
   print   "   or an assembly pipeline for $sampleID was never begun.  You'll need to start\n";
   print   "   the pipeline from the beginning; please delete the entire \"$sampleID\" subdirectory\n";
   print   "   and rerun \"000_setup.pl\" again to do this (note: this WILL NOT affect other running\n";
   print   "   or completed assemblies in this project space).\n\n";

   exit(1);
}

my $maxStepIndex = 26;

my $lastSuccessfulStep = -1;

chomp( my $completionBlock = `grep -h 'COMPLETED SUCCESSFULLY' $lastLogFile 2>/dev/null` );

my @completionLines = split(/\n/, $completionBlock);

# Scan through the log lines to identify the last step that completed successfully.

foreach my $line ( @completionLines ) {
   
   if ( $line =~ /STEP\s+(\d+)\s+COMPLETED\s+SUCCESSFULLY/ ) {
      
      my $completedID = $1;

      $completedID += 0;

      if ( $completedID > $lastSuccessfulStep ) {
         
         $lastSuccessfulStep = $completedID;
      }
   }
}

if ( $lastSuccessfulStep == $maxStepIndex ) {
   
   # The whole pipeline completed successfully.  Don't do anything.

   print "\n   FATAL: The pipeline for sample $sampleID ran successfully to completion,\n";
   print   "   according to the logfile.  If you want to restart it from scratch, please\n";
   print   "   delete the entire \"$sampleID\" subdirectory and rerun \"000_setup.pl\"\n";
   print   "   again to do this (note: this WILL NOT affect other running or completed\n";
   print   "   assemblies in this project space).\n\n";

   exit(1);

} elsif ( $lastSuccessfulStep == -1 ) {
   
   # No steps completed successfully.  Direct the user to another script.
   
   print "\n   FATAL: No steps completed successfully for sample $sampleID.  You'll need to start\n";
   print   "   the pipeline from the beginning; please delete the entire \"$sampleID\" subdirectory\n";
   print   "   and rerun \"000_setup.pl\" again to do this (note: this WILL NOT affect other running\n";
   print   "   or completed assemblies in this project space).\n\n";

   exit(1);

} else {
   
   # Archive partial log files to avoid confusing users who are trying to monitor
   # the current state of their pipelines.

   system("mv $asmLogDir/$jobNamePrefix.$sampleID.* $asmLogDir/.partial/");

   # The last successful step has been identified, and it's not the last one.
   # Filter the already-extant controller script to create a command subset
   # which will resume the pipeline at the appropriate step.

   my $firstStepToRun = sprintf("%02d", ($lastSuccessfulStep + 1));

   print "\nResuming pipeline for sample $sampleID:\n\n";

   # Rewrite the controller to execute only those steps that remain.

   print "   Writing a resumption-controller script...";

   open IN, "<$masterControlScript" or die("Can't open $masterControlScript for reading.\n");

   my $resumeScript = "$controlScriptDir/$sampleID\.resumeAtStep$firstStepToRun.pl";

   open OUT, ">$resumeScript" or die("Can't open $resumeScript for writing.\n");

   my $recording = 1;

   my $firstStepName = '';

   while ( my $line = <IN> ) {
      
      if ( $line =~ /^#\s+Step\s(\d+):\s+(\S+)/ ) {
         
         my $currentStep = $1;

         my $stepName = $2;

         if ( $currentStep < $firstStepToRun ) {
            
            $recording = 0;

            print OUT $line;

         } else {
            
            if ( $firstStepName eq '' ) {
               
               $firstStepName = $stepName;
            }
            
            $recording = 1;

            print OUT $line;
         }

      } elsif ( $line =~ /^#/ ) {
         
         print OUT $line;
            
      } elsif ( $line eq "\n" ) {
         
         print OUT $line;

      } elsif ( $recording ) {
         
         print OUT $line;
      }
   }

   close OUT;

   system("chmod 755 $resumeScript");

   close IN;

   print "done.  Pipeline will resume at step $firstStepToRun (\"$firstStepName\").\n";

   # Launch the resume-controller script.

   print "   Launching new controller script...";

   chomp( my $pwd = `pwd` );

   if ( scalar( @excludeList ) > 0 ) {
      
      system("(qsub -V -b y -P $projectCode -q all.q -l mem_free=2G -l h=\"!("
               . join('|', @excludeList)
               . ")\" -N $jobNamePrefix.$sampleID -e $pwd/$asmLogDir -o $pwd/$asmLogDir -wd $pwd/$sampleID ../$resumeScript) > /dev/null 2>&1");

   } else {
      
      system("(qsub -V -b y -P $projectCode -q all.q -l mem_free=2G -N $jobNamePrefix.$sampleID -e $pwd/$asmLogDir -o $pwd/$asmLogDir -wd $pwd/$sampleID ../$resumeScript) > /dev/null 2>&1");
   }

   print "done.  Grid job ID is \"$jobNamePrefix.$sampleID\".\n\n";
}

