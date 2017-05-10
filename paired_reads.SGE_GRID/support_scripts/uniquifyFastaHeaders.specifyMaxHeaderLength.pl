#!/usr/bin/perl

use strict;

$| = 1;

my $inFile = shift;

my $maxLen = shift;

die("Usage: $0 <inFile> <max header length>\n") if ( not -e $inFile or ( $maxLen !~ /^\d+$/ or $maxLen == 0 ) );

open IN, "<$inFile" or die("Can't open $inFile for reading.\n");

my $outFile = $inFile;

if ( $inFile =~ /\.([^\.]+)$/ ) {
   
   my $ext = $1;

   $outFile =~ s/$ext$/unique_header_IDs.$ext/;

} else {
   
   $outFile .= '.unique_header_IDs.fna';
}

open OUT, ">$outFile" or die("Can't open $outFile for writing.\n");

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

      $i++;

   } else {
      
      print OUT "$line\n";
   }
}

close OUT;

close IN;


