#!/usr/bin/perl

use strict;

$| = 1;

# ARGUMENTS

my $inFile = shift;

my $maxLen = shift;

my $mapFile = shift;

die("Usage: $0 <inFile> <max header length> [<desired old-to-new ID-map file>]\n") if ( not -e $inFile or ( $maxLen !~ /^\d+$/ or $maxLen == 0 ) );

# PARAMETERS

my $recordMap = 0;

if ( $mapFile ne '' ) {
   
   $recordMap = 1;
}

# EXECUTION

open IN, "<$inFile" or die("Can't open $inFile for reading.\n");

my $outFile = $inFile;

if ( $inFile =~ /\.([^\.]+)$/ ) {
   
   my $ext = $1;

   $outFile =~ s/$ext$/unique_header_IDs.$ext/;

} else {
   
   $outFile .= '.unique_header_IDs.fna';
}

open OUT, ">$outFile" or die("Can't open $outFile for writing.\n");

if ( $recordMap ) {
   
   open MAP, ">$mapFile" or die("Can't open $mapFile for writing.\n");
}

my $i = 0;

while ( my $line = <IN> ) {
   
   chomp $line;

   if ( $line =~ /^>(\S+)(.*)$/ ) {
      
      my $id = $1;

      my $theRest = $2;

      my $newHeader = ">$id.$i$2\n";

      if ( length($newHeader) > $maxLen ) {
         
         $newHeader = ">TRUNCATED_ID.$i$2\n";

         if ( length($newHeader) > $maxLen ) {
            
            $newHeader = ">TRUNCATED_ID.$i\n";
         }
      }

      print OUT $newHeader;

      if ( $recordMap ) {
         
         my $newID = $newHeader;

         chomp( $newID );

         $newID =~ s/^>//;

         $newID =~ s/\s.*$//;

         print MAP "$id\t$newID\n";
      }

      $i++;

   } else {
      
      print OUT "$line\n";
   }
}

if ( $recordMap ) {
   
   close MAP;
}

close OUT;

close IN;


