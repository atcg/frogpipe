#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Bio::SeqIO;
use Bio::SearchIO;
use Data::Dumper;

my @blastResultsFiles;
my $targetsFile;
my @contigFiles;
my $matrixFile;
my $usage = "Usage: perl blast_2_contigs.pl --targets <target_sequences.fasta> --blasts <blast_results_file1.txt>,<blast_results_file2.txt>,<blast_results_file3.txt>,etc --contigs <contigs1.fastq>,<contigs2.fastq>,<contigs3.fastq>,etc --out <matrixfile.txt>\n The blast reports and the contigs file MUST be listed in the same order!!!";

GetOptions  ("blasts=s"      => \@blastResultsFiles,
             "targets=s"    => \$targetsFile,
             "contigs=s"    => \@contigFiles,
             "out=s"        => \$matrixFile);

@contigFiles = split(/,/,join(',',@contigFiles));
@blastResultsFiles = split(/,/,join(',',@blastResultsFiles));

#   if (scalar @blastResultsFiles < 2) {
#       print "Must supply comma-separated list of blast reports (--blasts).\n";
#       die "$usage";
#   } elsif (!defined $matrixFile) {
#       print "Must supply output file name (--out).\n";
#       die "$usage";
#   } elsif (scalar @contigFiles < 2) {
#       print "Must supply comma separated list of contig files (--contigs).\n";
#       die "$usage";
#   }


### We want to generate a data matrix that consists of the following:
###     1. All contigs that matched to a target region for each sample
###     2. Some sort of summary statistics that will help us to determine which
###         we should keep and which we should throw
### To do this, we create alignments each target region, including all of the contigs
### which blasted to that particular target.
###
### Assume, for simplicity, each target gets its own FASTA file.
###
### Step 1: create 3,500 files (or hashes/arrays containing Bio:Seq objects), one for each target region
### Step 2: for each target gather, a list of the contig identifiers for each sample that blast to the target
### Step 3: Use this list of contig identifiers to harvest the actual sequence data from the contig files (contigs.fa as outputted by velvet)
###             --Gather these as Bio::Seq objects and store them in the hashes
### Step 4: Print out the data to matrix files
### Step 5: Multiple alignment for each target region

my @targets; #an array of Bio::Seq objects holding the target sequences

my $targetsFactory = Bio::SeqIO->new(-file => "$targetsFile",
                                     -format => "fasta");

while ( my $seq = $targetsFactory->next_seq() ) {
    #compare the contig number here to the blast output
    push(@targets,$seq);
}

# create factories from each blast report
##### And also create a hash for each sample--this will later store all the results and hits
my @sampleResultsAndHits;
my @blastReportObjectsArray; #an array of Bio::SearchIO objects holding the blast reports
foreach my $ind_blast_report (@blastResultsFiles) {
    my $factoryName = $ind_blast_report . ".blastFactory";
    my $tempFactory = Bio::SearchIO->new(-format => 'blast',
                                         -file => $ind_blast_report);
    push(@blastReportObjectsArray, $tempFactory);
}

# Iterate through all the results for each blast report
# Each sample gets a hash. The keys in that hash are the names of the targets, and the values
#   an array of all the contig names that blast to the targets. Eventually we want
#   to dump all of the contigs that blast to a target (from all samples) to a file.

# Build an array of hashes, one for each sample

my @anonymousBlastResultsArray;

my $hashCounter = 0;
foreach my $blastReport (@blastReportObjectsArray) {
    while ( my $result = $blastReport->next_result() ) {
        my $resultName = $result->query_name;
        my @resultHits;
        #If there's a hit, harvest the contig number and do something with it.
        #Iterate through ALL hits for each result
        while(my $hit = $result->next_hit ) {
            push(@resultHits, $hit->name());
        }
        if (scalar(@resultHits) > 0) {
            $anonymousBlastResultsArray[$hashCounter]{$resultName} = \@resultHits;
            #$anonymousBlastResultsArray[$hashCounter]{$result} = \@resultHits; #If you want to have the result objects as the hash keys, instead of the names

        }
    }
    if (scalar(@anonymousBlastResultsArray) > $hashCounter) {
        $hashCounter++;
    }
}

# Testing
## print Dumper(\$anonymousBlastResultsArray[0]); # much better
## for my $href ( @anonymousBlastResultsArray ) {
##     print "Number of keys in hash: " . scalar (keys %$href) . "\n";
## }


# So now we have an array. Each element is a hash--one for each sample/blast results file.
# The keys in the hashes are the results that had 1 or more hits in the blast results (each
# can either be a text string with the contig name, or the actual Bio::Search::Result::ResultI
# object itself--choose in line 94/95). The values for each hash key are arrays that contain
# the deflines of the de novo contigs that blasted to the targets (the targets are the key
# values).

# Now we want to print each sample's results to data matrices.
#
# 1. Loop through the array, going through each hash, 1 by one.
# 2. For each key, create a text file if one does not exist. The name of the text file is the key
# 3. Take the values in the hash value arrays, pull their associated sequence objects from their
#       respective de novo assembled contig files, and print them to the text files

#print Dumper(@anonymousBlastResultsArray);



# Pull the contigs from the velvet assembly into hashes
# Each sample has a hash. The key is the defline of the contig, and the value is
# the Bio::Seq object.

#First an array of the seq input factories
my @contigObjectsFactoriesIn;
foreach my $ind_contig_assembly_files (@contigFiles) {
    my $tempInFactory = Bio::SeqIO->new(-format => 'fasta',
                                      -file => $ind_contig_assembly_files);
    push(@contigObjectsFactoriesIn, $tempInFactory);
}

my @assembledContigsHashesArray;
my $hashCounter2 = 0;
foreach my $seqIOins (@contigObjectsFactoriesIn) {
    while ( my $seq_contig = $seqIOins->next_seq() ) {
        my $seqName = $seq_contig->display_id;
        #Store sequence in hash--defline is the key, Bio::Seq object is the value
        $assembledContigsHashesArray[$hashCounter2]{$seqName} = $seq_contig;
        }
    $hashCounter++;
}

# Now we've got two arrays where each element is a hash.
# The first is an array where each element is a sample-specific hash where each
#   key is a target, and each value is an array of deflines of the matching contigs
#   for that sample. (@anonymousBlastResultsArray)
# The second is an array where each element is a sample-specific hash where each
#   key is a contig defline, and each value is a Bio::Seq object that holds the
#   sequence (@assembledContigsHashesArray)


# Now iterate through @anonymousBlastResultsArray--search through the @assembledContigsHashesArray
# to


# Build an array for each target that holds the contig deflines that match for all samples.
# Then we'll iterate through these arrays to look up the corresponding Bio::Seq objects from
# the velvet contigs file to dump into the text files.
unless(-d "alignments") {
    mkdir "alignments" or die "Can't mkdir: alignments: $!";
}

foreach my $sampleHash ( @anonymousBlastResultsArray ) {
    foreach my $key (keys %{$sampleHash}) {
        open (my $FH, ">>", "alignments/$key");
        my $seqout= Bio::SeqIO->new( -format => 'Fasta', -file => ">>alignments/$key");
        #print $FH Dumper(@$sampleHash{$key});
        foreach my $valuez (@$sampleHash{$key}){
            my @localArray = @{$valuez};
            foreach my $writeIt (@localArray) {
                #Search for $writeIt in @assembledContigsHashesArray elements
                foreach my $sampleContigsHash (@assembledContigsHashesArray) {
                    my %localSeqHash = %{$sampleContigsHash};
                    $seqout->write_seq($localSeqHash{$writeIt});
                }
            }
        } 
    }    
}

my $FilledDirectory = "alignments";

opendir(my $DIR_HANDLE, $FilledDirectory) or die $!;

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





