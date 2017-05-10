#!/usr/bin/perl

use strict;

$| = 1;

my $prefix = shift;

$prefix =~ s/\///g;

die("Usage: $0 <sample ID>\n") if ( $prefix eq '' );

chomp( my $pwd = `pwd` );

# Read in the SGE project code.

print STDERR "Getting project code: ";

my $projectCodeFile = 'zz_project_code.txt';

open IN, "<$projectCodeFile" or die("Can't open $projectCodeFile for reading.\n");

chomp( my $projectCode = <IN> );

close IN;

print STDERR "$projectCode.\n";

# Make sure the main pipeline isn't still running.

chomp( my $qstatResult = `(qstat -j mgaMaster.$prefix | head -1 ) 2>&1` );

if ( $qstatResult !~ /do\s+not\s+exist/ ) {
   
   print "\n   FATAL: A job is already on the grid, executing the main processing pipeline\n";
   print   "   for sample $prefix.  Its job ID is \'mgaMaster.$prefix\'; please either kill it\n";
   print   "   or allow it to complete before running this script.\n\n";

   exit(1);
}

print STDERR "Confirmed: no master currently running.\n";

# Remove old coredumps.

print STDERR "Removing old coredumps...";

system("rm -f $pwd/$prefix/02_workDir/core.\*");

print STDERR "done.\n";

# Load the IDs of all the khmer-generated partitions that were to have been assembled.

print STDERR "Loading partition IDs...";

my $inputDir = "$pwd/$prefix/05_inputLinks";

opendir DOT, $inputDir or die("Can't open $inputDir for scanning.\n");

my @files = sort { $a cmp $b } grep { /\_1\.final\.newbler\-ready\.fna$/ } readdir DOT;

closedir DOT;

my @partitionIDs = ();

foreach my $file ( @files ) {
   
   $file =~ /(\d+)\_\d\.final/;

   my $partitionID = $1;

   push @partitionIDs, $partitionID;
}

print STDERR "got " . scalar( @partitionIDs ) . ".\n";

# Check the log file for each partition to see if its assembly finished successfully.  If not, save the ID for relaunch.

my $anyFailed = 0;

foreach my $id ( @partitionIDs ) {
   
   # Get the name of the most recent log file for the assembly of this partition.

   print STDERR "Finding log file for partition $id...";

   chomp( my $logFile = `ls -tr $pwd/$prefix/01_logs/mga26.nb.$prefix\_$id.o[0-9]\* 2> /dev/null | tail -1` );

   print STDERR "done.\n";

   # See if it succeeded.

   if ( -e $logFile ) {
      
      print STDERR "Checking log file for partition $id...";

      chomp( my $checkResult = `tail -q -n 1 $logFile` );

      print STDERR "done.\n";

      if ( $checkResult !~ /^Assembly\s+computation\s+succeeded/ ) {
         
         # Check to see if the assembly for this particular partition is still running.  If it is, don't do anything; force the user to either wait or kill the job.

         chomp( my $assemblyJobCheck = `/local/devel/abrady/metagenomic_assembly_SOP/support_scripts/qstatFullNames.sh` );

         if ( $assemblyJobCheck =~ /mga26.ctl.$prefix\_$id/ ) {
            
            # Still running.  Don't do anything.

            print("WARNING: assembly job for partition $id is still running.  Please either kill it or wait for it to complete.  Aborting relaunch for this partition.\n");

         } else {
            
            # This one failed.

            $anyFailed = 1;

            my $bottomLevelLauncher = "$pwd/$prefix/zz26a_run_newbler_scripts/zz26a_run_newbler__$id.sh";

            if ( not -e $bottomLevelLauncher ) {
               
               die("FATAL: Can't find bottom-level assembly-launcher script \"$bottomLevelLauncher\"; aborting.\n");
            }

            print STDERR "Relaunching $prefix\_$id...";

            my $relaunchCommand = "qsub -q all.q -l mem_free=2G -V -b y -P $projectCode -N mga26.ctl.$prefix\_$id -e $pwd/$prefix/01_logs -o $pwd/$prefix/01_logs -wd $pwd/$prefix/02_workDir $bottomLevelLauncher";

            system("$relaunchCommand\n");

            print STDERR "done.\n";
         }
      }

   } else {
      
      # Check to see if the assembly for this particular partition is still running.  If it is, don't do anything; force the user to either wait or kill the job.

      chomp( my $assemblyJobCheck = `/local/devel/abrady/metagenomic_assembly_SOP/support_scripts/qstatFullNames.sh` );

      if ( $assemblyJobCheck =~ /mga26.ctl.$prefix\_$id/ ) {
         
         # Still running.  Don't do anything.

         print("WARNING: assembly job for partition $id is still running.  Please either kill it or wait for it to complete.  Aborting relaunch for this partition.\n");

      } else {
         
         # This one failed.

         $anyFailed = 1;

         my $bottomLevelLauncher = "$pwd/$prefix/zz26a_run_newbler_scripts/zz26a_run_newbler__$id.sh";

         if ( not -e $bottomLevelLauncher ) {
            
            die("FATAL: Can't find bottom-level assembly-launcher script \"$bottomLevelLauncher\"; aborting.\n");
         }

         print STDERR "Relaunching $prefix\_$id...";

         my $relaunchCommand = "qsub -q all.q -l mem_free=2G -V -b y -P $projectCode -N mga26.ctl.$prefix\_$id -e $pwd/$prefix/01_logs -o $pwd/$prefix/01_logs -wd $pwd/$prefix/02_workDir $bottomLevelLauncher";

         system("$relaunchCommand\n");

         print STDERR "done.\n";
      }
   }
}

if ( not $anyFailed ) {
   
   print "All partition assemblies completed successfully for $prefix; no need for relaunch.\n";
}


