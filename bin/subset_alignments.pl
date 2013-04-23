#!/usr/bin/perl

use strict;
use warnings;
use File::Copy;
use Getopt::Long;

my $directory = ".";

GetOptions ("dir=s" => \$directory);

opendir(my $DIR_HANDLE, $directory) or die $!;

while (my $contigFile = readdir($DIR_HANDLE)) {
    next if $contigFile =~ /DS_Store/ or $contigFile =~ /subset_alignments.pl/;
    my %resultsHash;
    open (my $indContigFile, "<", $contigFile);
    while (my $line = <$indContigFile>) {
        # add sample number as a hash key if it doesn't exist
        if ($line =~ /^>sample_(\d+).*/) {
            if (!exists $resultsHash{$!}) {
                $resultsHash{$1} = 1;
            } else {
                $resultsHash{$1}++;
            }
        }
    }
    # If %resultsHash has a certain number of hash keys, then spit that contig
    # file into a new folder
    my $num_winners = scalar(keys %resultsHash);
    unless (-d $num_winners) {
        mkdir $num_winners;
    }
    close $indContigFile;
    my $oldlocation = "$contigFile";
    my $newlocation = "$num_winners/$contigFile";
    move($oldlocation, $newlocation);
}
closedir($DIR_HANDLE);




