#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $directory;

GetOptions ("dir=s" => \$directory);

opendir(my $DIR_HANDLE, $directory) or die $!;

while (my $contigFile = readdir($DIR_HANDLE)) {
    my %resultsHash;
    while (my $line = <$contigFile>) {
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
        
        
        
}
closedir($DIR_HANDLE);

