#!/usr/bin/perl

#frogpipe.pl, by Evan McCartney-Melstad (evanmelstad@ucla.edu)
#February 9, 2013

#See http://biologytomorrow.com/wiki/doku.php?id=shaffer:frogs for a description
#of what this pipeline is actually doing

#Usage: perl frogpipe.pl -a adapterSequences.fasta -f 19825_S1_L001_R1_001.fastq -r 19825_S1_L001_R2_001.fastq -s 19825

use strict;
use warnings;
use Getopt::Long;

my $adapterFile;
my $fastqF;
my $fastqR;
my $sampleID;
my $usage = "Usage: perl frogpipe.pl -a adapterSequences.fasta -f 19825_S1_L001_R1_001.fastq -r 19825_S1_L001_R2_001.fastq -s 19825\n";

GetOptions ( "a=s" => \$adapterFile,
             "f=s" => \$fastqF,
             "r=s" => \$fastqR,
             "s=s" => \$sampleID);

if ($adapterFile eq '') {
    print "Must supply fasta file with adapter sequence(s).\n";
    die "$usage";
} elsif ($fastqF eq '') {
    print "Must supply forward fastq file.\n";
    die "$usage";
} elsif ($fastqR eq '') {
    print "Must supply reverse fastq file. \n";
    die "$usage";
} elsif ($sampleID eq '') {
    print "Must supply sample identifier.\n";
    die "$usage";
}

#Run Scythe (https://github.com/ucdavis-bioinformatics/scythe)
#Usage: scythe -a adapter_file.fasta sequence_file.fastq
my $scytheOutputF = $fastqF . "_scythed";
my $scytheOutputR = $fastqR . "_scythed";
system("scythe -a $adapterFile -q sanger -o $scytheOutputF $fastqF");
system("scythe -a $adapterFile -q sanger -o $scytheOutputR $fastqR");

#Run Sickle (https://github.com/ucdavis-bioinformatics/sickle)
#Usage: sickle pe -f <paired-end fastq file 1> -r <paired-end fastq file 2> -t <quality type> -o <trimmed pe file 1> -p <trimmed pe file 2> -s <trimmed singles file>
my $sickleOutputPE_1 = $scytheOutputF . "_sickled";
my $sickleOutputPE_2 = $scytheOutputR . "_sickled";
my $sickleOutputSingles = $sampleID . "_scythed_sickled_singletons";
system("sickle pe -f $scytheOutputF -r $scytheOutputR -t sanger -o $sickleOutputPE_1 -p $sickleOutputPE_2 -s $sickleOutputSingles");

#    Merge reads in case the fragment was > 2 times read length (and they overlap): http://ccb.jhu.edu/software/FLASH/
#        (Creates histogram of read lengths. For sample 19825, approximately 50% of reads overlapped (indicating fragments less than 500bp)).












#    Map reads to human and e. coli genomes to filter out contamination (bowtie 2)
#        Set a few environmental variables for bowtie2 (this isn't essential, but saves some typing later on):
#            $BOWTIE2_INDEXES = directory where your genome indices live
#            $BT2_HOME = directory where the bowtie2 binaries live (something like ~/bin/bowtie2-2.0.6
#        Install bowtie2, and build genome indices for human/e. coli/anything else that should be filtered out (this takes a long time)
#        bowtie2 -q Ðphred33 Ðmaxins 2000 -p 7 Ðun ~/Desktop/Frogs_nextgen/Feb8/19825_nohuman_unpaired.txt Ðal ~/Desktop/Frogs_nextgen/Feb8/19825_HUMAN_unpaired.txt Ðun-conc ~/Desktop/Frogs_nextgen/Feb8/19825_noHuman_paired.txt Ðal-conc ~/Desktop/Frogs_nextgen/Feb8/19825_HUMAN_paired.txt -x /mnt/Data1/human_genome/hg19 {-1 ~/Desktop/Frogs_nextgen/Feb8/19825_notCombined_1.fastq -2 ~/Desktop/Frogs_nextgen/Feb8/19825_notCombined_2.fastq | -U ~/Desktop/Frogs_nextgen/Feb8/19825_Combined.fastq}
#            The above command uses 7 threads (so make sure you have 8 cores, or else set this to 3 or 4), a maximum fragment length of 2000 (which is a lot higher than their default value),

