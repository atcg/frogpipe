#!/usr/bin/perl

# frogpipe.pl, by Evan McCartney-Melstad (evanmelstad@ucla.edu)
# February 9, 2013

# See http://biologytomorrow.com/wiki/doku.php?id=shaffer:frogs for a description
# of what this pipeline is actually doing

# Usage: perl frogpipe.pl -a adapterSequences.fasta -f 19825_S1_L001_R1_001.fastq -r 19825_S1_L001_R2_001.fastq -s 19825

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

if (!defined $adapterFile) {
    print "Must supply fasta file with adapter sequence(s).\n";
    die "$usage";
} elsif (!defined $fastqF) {
    print "Must supply forward fastq file.\n";
    die "$usage";
} elsif (!defined $fastqR) {
    print "Must supply reverse fastq file. \n";
    die "$usage";
} elsif (!defined $sampleID) {
    print "Must supply sample identifier.\n";
    die "$usage";
}

unless(-d "data") {
    mkdir "data" or die "can't mkdir data: $!";
}

unless(-d "data/clean_data") {
    mkdir "data/clean_data" or die "can't mkdir data/clean_data: $!";
}

unless(-d "data/sam") {
    mkdir "data/sam" or die "can't mkdir data/sam: $!";
}

unless(-d "data/incremental") {
    mkdir "data/incremental" or die "can't mkdir data/incremental: $!";
}

print '***** frogpipe.pl, by Evan McCartney-Melstad (evanmelstad@ucla.edu) *****' . "\n";
print "***** Adapter sequences: $adapterFile *****\n";
print "***** First fastq file:  $fastqF *****\n";
print "***** Second fastq file: $fastqR *****\n";
print "***** Sample identifier: $sampleID *****\n\n\n\n";



#Remove redundant and low-complexity reads (while maintaining the integrity of mate pairs)




## Run Scythe (https://github.com/ucdavis-bioinformatics/scythe)
## Usage: scythe -a adapter_file.fasta sequence_file.fastq
print "***** Running Scythe on each fastq file to clean up 3' ends for adapter contaminants *****\n";
my $scytheOutputF = $fastqF . "_scythed";
my $scytheOutputR = $fastqR . "_scythed";
system("~/bin/scythe/scythe -a $adapterFile -q sanger -o data/incremental/$scytheOutputF $fastqF");
print "\n";
system("~/bin/scythe/scythe -a $adapterFile -q sanger -o data/incremental/$scytheOutputR $fastqR");
print "***** Scythe finished running *****\n\n\n";

# Run Sickle (https://github.com/ucdavis-bioinformatics/sickle)
# Usage: sickle pe -f <paired-end fastq file 1> -r <paired-end fastq file 2> -t <quality type> -o <trimmed pe file 1> -p <trimmed pe file 2> -s <trimmed singles file>
my $sickleOutputPE_1 = $scytheOutputF . "_sickled";
my $sickleOutputPE_2 = $scytheOutputR . "_sickled";
my $sickleOutputSingles = $sampleID . "_scythed_sickled_singletons";
print "***** Running Sickle on paired end files to trim to longest reads of acceptable quality *****\n";
system("~/bin/sickle/sickle pe -f data/incremental/$scytheOutputF -r data/incremental/$scytheOutputR -q 20 -n -t sanger -o data/incremental/$sickleOutputPE_1 -p data/incremental/$sickleOutputPE_2 -s data/incremental/$sickleOutputSingles");
print "***** Sickle finished running *****\n\n\n";


# Merge reads in case the fragment was > 2 times read length (and they overlap):   
my $fastq_join_Output_Prefix = $sampleID . "_scythed_sickled_fastq-joined";
my $fastq_join_Output1 = $fastq_join_Output_Prefix . ".un1.fastq"; #this file will be created below by fastq-join
my $fastq_join_Output2 = $fastq_join_Output_Prefix . ".un2.fastq"; #this file will be created below by fastq-join
my $fastq_join_Output_JOINED = $fastq_join_Output_Prefix . ".join.fastq"; #this file will be created below by fastq-join
print "***** Running fastq-join on paired end files to merge overlapping paired-end reads (in case some fragments were shorter than 2x read length) *****\n";
system("~/bin/ea-utils.1.1.2-537/fastq-join data/incremental/$sickleOutputPE_1 data//incremental/$sickleOutputPE_2 -o data/incremental/$fastq_join_Output_Prefix.%.fastq -m 15 -p 1");
print "***** Fastq-join finished running *****\n\n\n";

#So at this point, we have several useful QC'ed files (filenames below assume usage example from line 9 above).
# 1. 19825_scythed_sickled_singletons, which is the file that contains the non-paired end reads (when sickle kicked out a poor quality read, its good-quality partner went into this file)
# 2. 19825_scythed_sickled_fastq-joined.join.fastq, which contains the paired end reads that have been merged by fastq-join
# 3. 19825_scythed_sickled_fastq-joined.un1.fastq, which contains the QC'ed reads from the first file that have not been merged
# 4. 19825_scythed_sickled_fastq-joined.un2.fastq, which contains the QC'ed reads from the second file that have not been merged

#Now filter out reads from all of the four files above that align with human or e. coli using bowtie2
#should I add/remove the --no-mixed or --no-discordant flags?
my $noHumanReadsSingles = $sickleOutputSingles . "_noHuman";
my $humanReadsSingles = $sickleOutputSingles . "_HUMAN";
my $singlesNoHumanSam = $sickleOutputSingles . "_humanfilter_bowtie2.sam";

my $noHumanReadsJoined = $fastq_join_Output_JOINED . "_noHuman";
my $humanReadsJoined = $fastq_join_Output_JOINED . "_HUMAN";
my $joinedNoHumanSam = $fastq_join_Output_JOINED . "_humanfilter_bowtie2.sam";

my $noHumanReadsPairs = $sampleID . "pairs_noHuman";
my $humanReadsPairs = $sampleID . "pairs_HUMAN";
my $pairsNoHumanSam = $sampleID . "_humanfilter_bowtie2.sam";
my $noHumanReadsPairsOut1 = $noHumanReadsPairs . ".1";
my $noHumanReadsPairsOut2 = $noHumanReadsPairs . ".2";

my $noHumanNoEColiSingles = $noHumanReadsSingles . "_noEColi";
my $noHumanYesEColiSingles = $noHumanReadsSingles . "_YES-EColi";
my $singlesNoHumanNoEColiSam = $noHumanReadsSingles . "_ecoliFilter_bowtie2.sam";

my $noHumanNoEColiJoined = $noHumanReadsJoined . "_noEColi";
my $noHumanYesEColiJoined = $noHumanReadsJoined . "_YES-EColi";
my $joinedNoHumanNoEColiSam = $noHumanReadsJoined . "_ecoliFilter_bowtie2.sam";

my $noHumanNoEColiPairs = $noHumanReadsPairs . "_noEColi";
my $noHumanYesEColiReadsPairs = $noHumanReadsPairs . "_YES-EColi";
my $pairsNoHumanNoEColiSam = $noHumanReadsPairs . "_ecoliFilter_bowtie2.sam";
my $noHumanNoEColiOut1 = $noHumanNoEColiPairs . ".1";
my $noHumanNoEColiOut2 = $noHumanNoEColiPairs . ".2";


my $genomeDir = $ENV{'BOWTIE2_INDEXES'};
print "***** Checking to see if reads align to the human genome to remove contaminants ****\n";
system("~/bin/bowtie2-2.0.6/bowtie2 -q --phred33 --threads 7 --un data/incremental/$noHumanReadsSingles --al data/incremental/$humanReadsSingles -x $genomeDir/hg19 -U data/incremental/$sickleOutputSingles -S data/sam/$singlesNoHumanSam");
system("~/bin/bowtie2-2.0.6/bowtie2 -q --phred33 --threads 7 --un data/incremental/$noHumanReadsJoined --al data/incremental/$humanReadsJoined -x $genomeDir/hg19 -U data/incremental/$fastq_join_Output_JOINED -S data/sam/$joinedNoHumanSam");
system("~/bin/bowtie2-2.0.6/bowtie2 -q --phred33 --minins 0 --maxins 2000 --no-mixed --no-discordant --threads 7 --un-conc data/incremental/$noHumanReadsPairs --al-conc data/incremental/$humanReadsPairs -x $genomeDir/hg19 -1 data/incremental/$fastq_join_Output1 -2 data/incremental/$fastq_join_Output2 -S data/sam/$pairsNoHumanSam");
print "***** Finished checking for human contaminants *****\n\n\n";

print "***** Checking to see if reads align to the E. coli genome to remove contaminants *****\n";
system("~/bin/bowtie2-2.0.6/bowtie2 -q --phred33 --threads 7 --un data/clean_data/$noHumanNoEColiSingles --al data/incremental/$noHumanYesEColiSingles -x $genomeDir/hg19 -U data/incremental/$noHumanReadsSingles -S data/sam/$singlesNoHumanNoEColiSam");
system("~/bin/bowtie2-2.0.6/bowtie2 -q --phred33 --threads 7 --un data/clean_data/$noHumanNoEColiJoined --al data/incremental/$noHumanYesEColiJoined -x $genomeDir/hg19 -U data/incremental/$noHumanReadsJoined -S data/sam/$joinedNoHumanNoEColiSam");
system("~/bin/bowtie2-2.0.6/bowtie2 -q --phred33 --minins 0 --maxins 2000 --no-mixed --no-discordant --threads 7 --un-conc data/clean_data/$noHumanNoEColiPairs --al-conc data/incremental/$noHumanYesEColiReadsPairs -x $genomeDir/hg19 -1 data/incremental/$noHumanReadsPairsOut1 -2 data/incremental/$noHumanReadsPairsOut2 -S data/sam/$pairsNoHumanNoEColiSam");
print "***** Finished checking for E. coli contaminants *****\n\n\n";


#de novo assembly of reads into contigs
#Abyss