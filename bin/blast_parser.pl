#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Bio::SearchIO;

my $inFile1;
my $inFile2;
my $inFile3;
my $inFile4;
my $inFile5;
my $inFile6;
my $inFile7;
my $inFile8;
my $outFile;
my $usage = "usage: perl blast_parser.pl -in <infile.txt> -out <outfile.txt>";

GetOptions  ("1=s" => \$inFile1,
             "2=s" => \$inFile2,
             "3=s" => \$inFile3,
             "4=s" => \$inFile4,
             "5=s" => \$inFile5,
             "6=s" => \$inFile6,
             "7=s" => \$inFile7,
             "8=s" => \$inFile8,
             "out=s" => \$outFile);

if (!defined $inFile1) {
    print "Must supply input file 1.\n";
    die "$usage";
}
 elsif (!defined $inFile2) {
    print "Must supply input file 2.\n";
    die "$usage";
} elsif (!defined $inFile3) {
    print "Must supply input file 3.\n";
    die "$usage";
} elsif (!defined $inFile4) {
    print "Must supply input file 4.\n";
    die "$usage";
} elsif (!defined $inFile5) {
    print "Must supply input file 5.\n";
    die "$usage";
} elsif (!defined $inFile6) {
    print "Must supply input file 6.\n";
    die "$usage";
} elsif (!defined $inFile7) {
    print "Must supply input file 7.\n";
    die "$usage";
} elsif (!defined $inFile8) {
    print "Must supply input file 8.\n";
    die "$usage";
}
elsif (!defined $outFile) {
    print "Must supply output file name.\n";
    die "$usage";
}


# We want to read in the blast output files of each individual and create an array
# that holds that target contig numbers of all targets that have matches. Then
# compare these arrays to see which targets have matching contigs in all individuals
#
my $sample1 = new Bio::SearchIO(-format => 'blast',
                                -file => "$inFile1");
my $sample2 = new Bio::SearchIO(-format => 'blast',
                                -file => "$inFile2");
my $sample3 = new Bio::SearchIO(-format => 'blast',
                                -file => "$inFile3");
my $sample4 = new Bio::SearchIO(-format => 'blast',
                                -file => "$inFile4");
my $sample5 = new Bio::SearchIO(-format => 'blast',
                                -file => "$inFile5");
my $sample6 = new Bio::SearchIO(-format => 'blast',
                                -file => "$inFile6");
my $sample7 = new Bio::SearchIO(-format => 'blast',
                                -file => "$inFile7");
my $sample8 = new Bio::SearchIO(-format => 'blast',
                                -file => "$inFile8");

my @sample1_array;
my @sample2_array;
my @sample3_array;
my @sample4_array;
my @sample5_array;
my @sample6_array;
my @sample7_array;
my @sample8_array;

while (my $result = $sample1->next_result) {
    my $numHits = $result->num_hits;
    if ($numHits > 0) {
        push (@sample1_array, $result->query_name);
    }
}

while (my $result = $sample2->next_result) {
    my $numHits = $result->num_hits;
    if ($numHits > 0) {
        push (@sample2_array, $result->query_name);
    }
}

while (my $result = $sample3->next_result) {
    my $numHits = $result->num_hits;
    if ($numHits > 0) {
        push (@sample3_array, $result->query_name);
    }
}

while (my $result = $sample4->next_result) {
    my $numHits = $result->num_hits;
    if ($numHits > 0) {
        push (@sample4_array, $result->query_name);
    }
}

while (my $result = $sample5->next_result) {
    my $numHits = $result->num_hits;
    if ($numHits > 0) {
        push (@sample5_array, $result->query_name);
    }
}

while (my $result = $sample6->next_result) {
    my $numHits = $result->num_hits;
    if ($numHits > 0) {
        push (@sample6_array, $result->query_name);
    }
}

while (my $result = $sample7->next_result) {
    my $numHits = $result->num_hits;
    if ($numHits > 0) {
        push (@sample7_array, $result->query_name);
    }
}

while (my $result = $sample8->next_result) {
    my $numHits = $result->num_hits;
    if ($numHits > 0) {
        push (@sample8_array, $result->query_name);
    }
}

# Smart match through the arrays. Start with array 1, and if it matches all of them,
# then it's a good hit. If a record from sample1 does not match all of them, then it's
# no good. This is the only match you need to do.
open (my $outputFH, ">", $outFile);

foreach my $sample1hits (@sample1_array) {
    if ($sample1hits ~~ @sample2_array and
        $sample1hits ~~ @sample3_array and
        $sample1hits ~~ @sample4_array and
        $sample1hits ~~ @sample5_array and
        $sample1hits ~~ @sample6_array and
        $sample1hits ~~ @sample7_array and
        $sample1hits ~~ @sample8_array) {
        print $outputFH "$sample1hits\n";
    }
}
close $outputFH;

