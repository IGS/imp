#!/usr/bin/perl

#########################################################################
#                                                                       #
# Copyright 2012 Arthur Brady (abrady@umiacs.umd.edu).                  #
#                                                                       #
# Last revision 2012.11.06.1405.                                        #
#                                                                       #
# This program is free software: you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License as published by  #
# the Free Software Foundation, either version 3 of the License, or     #
# (at your option) any later version.                                   #
#                                                                       #
# This program is distributed in the hope that it will be useful,       #
# but WITHOUT ANY WARRANTY; without even the implied warranty of        #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
# GNU General Public License for more details.                          #
#                                                                       #
# You should have received a copy of the GNU General Public License     #
# along with this program.  If not, see <http://www.gnu.org/licenses/>. #
#                                                                       #
#########################################################################

use strict;

my $idFile = shift;

my $seqFile = shift;

my $outFile = shift;

if ( not -e $idFile ) {
   
   if ( $outFile ne '' ) {
      
      system("touch $outFile.failed");
   }
   
   die("Usage: $0 <file containing sequence IDs to be PRESERVED> <fasta input> [<fasta output filename>]\n");
}

if ( not open IN, "<$idFile" ) {
   
   if ( $outFile ne '' ) {
      
      system("touch $outFile.failed");

      die("Can't open $idFile for reading.\n");
   }
}

my $toKeep = {};

print STDERR "Scanning read list...\n\n";

my $scannedCount = 0;

while ( my $line = <IN> ) {
   
   chomp $line;

   $toKeep->{$line} = 1;

   $scannedCount++;

   if ( $scannedCount == 1000000 ) {
      
      print STDERR "   ...scanned $scannedCount entries...";

   } elsif ( $scannedCount % 1000000 == 0 ) {
      
      print STDERR "\r   ...scanned $scannedCount entries...";
   }
}

my $nrCount = keys %$toKeep;

print STDERR "\n\n...done.  Scanned $scannedCount entries in all (recorded $nrCount nonredundant IDs).\n";

close IN;

if ( $outFile eq '' ) {
   
   $outFile = $seqFile;

   $outFile =~ s/^.*\/([^\/]+)$/$1/;

   if ( $outFile =~ /\./ ) {
      
      $outFile =~ s/\.([^\.]+)$/_stripped\.$1/;

   } else {
      
      $outFile .= '_stripped.fasta';
   }
}

print STDERR "Parsing $seqFile and writing filtered output to $outFile...\n\n";

if ( not open IN, "<$seqFile" ) {
   
   system("touch $outFile.failed");

   die("Can't open $seqFile for reading.\n");
}

if ( not open OUT, ">$outFile" ) {
   
   system("touch $outFile.failed");
   
   die("Can't open $outFile for writing.\n");
}

my $recording = 1;

my $recorded = 0;

my $faScanned = 0;

while ( chomp( my $line = <IN> ) ) {
   
   if ( $line =~ /^>(\S+)/ ) {
      
      my $id = $1;

      $id =~ s/\/[12]$//;

      $recording = 0;

      $faScanned++;

      if ( $toKeep->{$id} ) {
         
         $recording = 1;

	 print OUT "$line\n";

         $recorded++;

         if ( $recorded == 1000000 ) {
            
            print STDERR "   ...copied $recorded / $faScanned entries...";

         } elsif ( $recorded % 1000000 == 0 ) {
            
            print STDERR "\r   ...copied $recorded / $faScanned entries...";
         }

      } else {
	 
	 $recording = 0;
      }

   } elsif ( $recording ) {
	 
      print OUT "$line\n";
   }
}

close OUT;

close IN;

system("touch $outFile.complete");

print STDERR "\n\ndone.  Copied $recorded / $faScanned entries in all.\n";

