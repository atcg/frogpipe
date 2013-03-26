#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Bio::SeqIO;
use Bio::Seq;
use Bio::PrimarySeq;

my $inFile;
my $outFile;
my $sampleID;
my $usage = "Usage: perl rename_velvet_contigs.pl -i <infile.txt> -o <outfile.txt>\n";

GetOptions  ("in=s"     => \$inFile,
             "sample=s" => \$sampleID,
             "out=s"    => \$outFile);

if (!defined $inFile) {
    print "Must supply input file name.\n";
    die "$usage";
} elsif (!defined $outFile) {
    print "Must supply output file name.\n";
    die "$usage";
}

my $in = Bio::SeqIO->new(-file => $inFile,
                                 -format => 'fasta');
my $out = Bio::SeqIO->new(-file => ">$outFile" ,
                          -format => 'fasta');

while ( my $seq = $in->next_seq() ) {
    my $begID = $seq->display_id;
    my $changedID = $sampleID . "__$begID";
    $seq->display_id($changedID);
    $out->write_seq($seq);
}