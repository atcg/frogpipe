#!/usr/bin/perl

use strict;
use warnings;
use File::Copy;
use Getopt::Long;
use List::MoreUtils;
use Data::Dumper;

my $inDir;
my $outDir;
my $usage = "Usage: perl xxxxx.pl -in </dir/with/fastq_and_adapters> -out </output/dir>\n"; ##CHANGE THIS LINE

GetOptions  ("in=s" => \$inDir,
             "out=s" => \$outDir);

if (!defined $inDir) {
    print "Must supply input directory.\n";
    die "$usage";
} elsif (!defined $outDir) {
    print "Must supply output file name.\n";
    die "$usage";
}


# Gather all files in directory and determine which samples are present
# Each sample should have a forward fastq, reverse fastq, and adapters file
my @inDirFiles;
opendir(INDIR, $inDir) or die "Couldn't open input directory: $!\n";
while (my $file = readdir(INDIR)) {
    push(@inDirFiles, $file);
}
closedir(INDIR);

my @sampleNumbers;
foreach my $file (@inDirFiles) {
    if ($file =~ /(\d+)_S.*fastq/) {
        push(@sampleNumbers, $1);
    }
}

my %sampleNumberHash;
foreach my $number (@sampleNumbers) {
    if ($sampleNumberHash{$number}) {
        $sampleNumberHash{$number}++;
    } else {
        $sampleNumberHash{$number} = 1;
    }
}

my @adapterFiles;
foreach my $i (@inDirFiles) {
    if ($i =~ /adapters_(\d+).fa*/) {
        push (@adapterFiles, $1);
    }
}

foreach my $adapter (@adapterFiles) {
    if ($sampleNumberHash{$adapter}) {
        $sampleNumberHash{$adapter}++;
    }
}

# iterate through hash keys--all keys should have a value of 3. If they do, then
# run frogpipe on those samples
my @sample_numbers_to_run;
while ((my $key, my $value) = each(%sampleNumberHash)) {
    if ($value == 3) {
        print "Two fastq files and an adapter file found for $key: proceeding with frogpipe.pl\n";
        push (@sample_numbers_to_run, $key);
    }
}

# Each key is a sample, each value is an array with four values: 1) adapters filename<
# 2) forward fastq filename, 3) reverse fastq filename, 4) sampleID
my %runHash;
foreach my $finalSample (@sample_numbers_to_run) {
    my @resultsFiles;
    foreach my $innerFiles (@inDirFiles) {
        if ($innerFiles =~ /$finalSample/) {
            push (@resultsFiles, $innerFiles);
        }
    }
    my @sortedResults = sort(@resultsFiles);
    $runHash{$finalSample} = \@sortedResults;
}

### To view what commands will be printed uncomment the below three lines
# while ((my $key, my $value) = each(%runHash)) {
#     print("perl frogpipe.pl -a @{$runHash{$key}}[2] -f @{$runHash{$key}}[0] -r @{$runHash{$key}}[1] -s $key > $key.log 2>&1\n");    
# }

while ((my $key, my $value) = each(%runHash)) {
    print "Running sample $key\n";
    print "Command: perl frogpipe.pl -a @{$runHash{$key}}[2] -f @{$runHash{$key}}[0] -r @{$runHash{$key}}[1] -s $key > $key.log 2>&1\n";
    system("perl frogpipe.pl -a @{$runHash{$key}}[2] -f @{$runHash{$key}}[0] -r @{$runHash{$key}}[1] -s $key > $key.log 2>&1");    
}
print "Finished running frogpipe.pl on all samples. \n";

# Now need to define things for blast_to_matrix.pl
# It needs --blasts, --targets, --contigs, and --out

my @blasts;
my $targets;
my @contigs;
my $blast2matrixout;

print "Creating data matrices from frogpipe.pl output.\n";
foreach my $runSample (@sample_numbers_to_run) {
    my $tempBlastFile = $runSample . "_piped/data/clean_data/blast/$runSample" . "_baits_blasted_to_velvetContigs.txt";
    my $tempContigFile = $runSample . "_piped/data/clean_data/velvet_optimizer/$runSample" . "_velvet_assembled_contigs_renamed.fa";
    push (@blasts, $tempBlastFile);
    push (@contigs, $tempContigFile);
}
my @sortedBlasts = sort(@blasts);
my @sortedContigs = sort(@contigs);
my $blastsFilesString = join(",", @sortedBlasts);
my $contigsFilesString = join(",", @sortedContigs);

system("perl blast_2_matrix.pl --blasts $blastsFilesString --targets singles.fasta --contigs $contigsFilesString --out alignments")
print "Matrix creation completed. Done!\n";