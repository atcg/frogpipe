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

my $pipeDir = "$sampleID" . "_piped";

unless(-d "$pipeDir") {
    mkdir "$pipeDir" or die "can't mkdir $pipeDir: $!";
}

unless(-d "$pipeDir/data") {
    mkdir "$pipeDir/data" or die "can't mkdir $pipeDir/data: $!";
}

unless(-d "$pipeDir/data/clean_data") {
    mkdir "$pipeDir/data/clean_data" or die "can't mkdir $pipeDir/data/clean_data: $!";
}

unless(-d "$pipeDir/data/sam") {
    mkdir "$pipeDir/data/sam" or die "can't mkdir $pipeDir/data/sam: $!";
}

unless(-d "$pipeDir/data/incremental") {
    mkdir "$pipeDir/data/incremental" or die "can't mkdir $pipeDir/data/incremental: $!";
}
#unless(-d "$pipeDir/data/ABYSS") {
#    mkdir "$pipeDir/data/ABYSS" or die "can't mkdir $pipeDir/data/ABYSS: $!";
#}
unless(-d "$pipeDir/data/clean_data/velvet") {
    mkdir "$pipeDir/data/clean_data/velvet" or die "can't mkdir $pipeDir/data/clean_data/velvet: $!";
}
unless(-d "$pipeDir/data/clean_data/blast") {
    mkdir "$pipeDir/data/clean_data/blast" or die "can't mkdir $pipeDir/data/clean_data/blast: $!";
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
system("~/bin/scythe/scythe -a $adapterFile -q sanger -o $pipeDir/data/incremental/$scytheOutputF $fastqF");
print "\n";
system("~/bin/scythe/scythe -a $adapterFile -q sanger -o $pipeDir/data/incremental/$scytheOutputR $fastqR");
print "***** Scythe finished running *****\n\n\n";

# Run Sickle (https://github.com/ucdavis-bioinformatics/sickle)
# Usage: sickle pe -f <paired-end fastq file 1> -r <paired-end fastq file 2> -t <quality type> -o <trimmed pe file 1> -p <trimmed pe file 2> -s <trimmed singles file>
my $sickleOutputPE_1 = $scytheOutputF . "_sickled";
my $sickleOutputPE_2 = $scytheOutputR . "_sickled";
my $sickleOutputSingles = $sampleID . "_scythed_sickled_singletons";
print "***** Running Sickle on paired end files to trim to longest reads of acceptable quality *****\n";
system("~/bin/sickle/sickle pe -f $pipeDir/data/incremental/$scytheOutputF -r $pipeDir/data/incremental/$scytheOutputR -q 20 -n -t sanger -o $pipeDir/data/incremental/$sickleOutputPE_1 -p $pipeDir/data/incremental/$sickleOutputPE_2 -s $pipeDir/data/incremental/$sickleOutputSingles");
print "***** Sickle finished running *****\n\n\n";


# Merge reads in case the fragment was > 2 times read length (and they overlap):   
my $fastq_join_Output_Prefix = $sampleID . "_scythed_sickled_fastq-joined";
my $fastq_join_Output1 = $fastq_join_Output_Prefix . ".un1.fastq"; #this file will be created below by fastq-join
my $fastq_join_Output2 = $fastq_join_Output_Prefix . ".un2.fastq"; #this file will be created below by fastq-join
my $fastq_join_Output_JOINED = $fastq_join_Output_Prefix . ".join.fastq"; #this file will be created below by fastq-join
print "***** Running fastq-join on paired end files to merge overlapping paired-end reads (in case some fragments were shorter than 2x read length) *****\n";
system("~/bin/ea-utils/fastq-join $pipeDir/data/incremental/$sickleOutputPE_1 $pipeDir/data/incremental/$sickleOutputPE_2 -o $pipeDir/data/incremental/$fastq_join_Output_Prefix.%.fastq -m 15 -p 1");
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
system("~/bin/bowtie2-2.0.6/bowtie2 -q --phred33 --threads 7 --un $pipeDir/data/incremental/$noHumanReadsSingles --al $pipeDir/data/incremental/$humanReadsSingles -x $genomeDir/hg19 -U $pipeDir/data/incremental/$sickleOutputSingles -S $pipeDir/data/sam/$singlesNoHumanSam");
system("~/bin/bowtie2-2.0.6/bowtie2 -q --phred33 --threads 7 --un $pipeDir/data/incremental/$noHumanReadsJoined --al $pipeDir/data/incremental/$humanReadsJoined -x $genomeDir/hg19 -U $pipeDir/data/incremental/$fastq_join_Output_JOINED -S $pipeDir/data/sam/$joinedNoHumanSam");
system("~/bin/bowtie2-2.0.6/bowtie2 -q --phred33 --minins 0 --maxins 2000 --no-mixed --no-discordant --threads 7 --un-conc $pipeDir/data/incremental/$noHumanReadsPairs --al-conc $pipeDir/data/incremental/$humanReadsPairs -x $genomeDir/hg19 -1 $pipeDir/data/incremental/$fastq_join_Output1 -2 $pipeDir/data/incremental/$fastq_join_Output2 -S $pipeDir/data/sam/$pairsNoHumanSam");
print "***** Finished checking for human contaminants *****\n\n\n";

print "***** Checking to see if reads align to the E. coli genome to remove contaminants *****\n";
system("~/bin/bowtie2-2.0.6/bowtie2 -q --phred33 --threads 7 --un $pipeDir/data/clean_data/$noHumanNoEColiSingles --al $pipeDir/data/incremental/$noHumanYesEColiSingles -x $genomeDir/ecoliK12 -U $pipeDir/data/incremental/$noHumanReadsSingles -S $pipeDir/data/sam/$singlesNoHumanNoEColiSam");
system("~/bin/bowtie2-2.0.6/bowtie2 -q --phred33 --threads 7 --un $pipeDir/data/clean_data/$noHumanNoEColiJoined --al $pipeDir/data/incremental/$noHumanYesEColiJoined -x $genomeDir/ecoliK12 -U $pipeDir/data/incremental/$noHumanReadsJoined -S $pipeDir/data/sam/$joinedNoHumanNoEColiSam");
system("~/bin/bowtie2-2.0.6/bowtie2 -q --phred33 --minins 0 --maxins 2000 --no-mixed --no-discordant --threads 7 --un-conc $pipeDir/data/clean_data/$noHumanNoEColiPairs --al-conc $pipeDir/data/incremental/$noHumanYesEColiReadsPairs -x $genomeDir/ecoliK12 -1 $pipeDir/data/incremental/$noHumanReadsPairsOut1 -2 $pipeDir/data/incremental/$noHumanReadsPairsOut2 -S $pipeDir/data/sam/$pairsNoHumanNoEColiSam");
print "***** Finished checking for E. coli contaminants *****\n\n\n";

#merge joined and singleton reads into a single file
my $joinedQCed = $sampleID . "scythed_sickled_nohuman_noecoli_combined_joined_and_singletons.fastq";
system("cat $pipeDir/data/clean_data/$noHumanNoEColiSingles $pipeDir/data/clean_data/$noHumanNoEColiJoined > $pipeDir/data/clean_data/$joinedQCed");


#de novo assembly of reads into contigs using velvet
print "***** Running de novo assembly of reads using velvet *****.\n";

system("velveth $pipeDir/data/clean_data/velvet 31 -short -fastq $pipeDir/data/clean_data/$joinedQCed -shortPaired2 -separate -fastq $pipeDir/data/clean_data/$noHumanNoEColiOut1 $pipeDir/data/clean_data/$noHumanNoEColiOut2");
system("velvetg $pipeDir/data/clean_data/velvet -exp_cov auto -cov_cutoff auto");
print "***** Finished running velvet *****.\n\n\n";

#blasting between baits and velvet-assembled contigs
my $contigsName = $sampleID . "_contigs";
my $blastResults = $sampleID . "_baits_blasted_to_velvetContigs.txt";
system("makeblastdb -in $pipeDir/data/clean_data/velvet/contigs.fa -dbtype nucl -title $contigsName -out $pipeDir/data/clean_data/blast/$contigsName");
system("blastn -db $pipeDir/data/clean_data/blast/$contigsName -query singles.fasta -out $pipeDir/data/clean_data/blast/$blastResults");





#########de novo assembly of reads into contigs using Abyss
#########This section is based on a script by Mark Phuong
########print "***** Revising sequence deflines for input into Abyss *****\n";
########my @abyssFiles = ("$pipeDir/data/clean_data/$joinedQCed", "$pipeDir/data/clean_data/$$noHumanNoEColiOut1", "$pipeDir/data/clean_data/$$noHumanNoEColiOut2");
########
########foreach my $fileToRename (@abyssFiles) {
########    open (my $fastqFH, "<", "$fileToRename") || die "Couldn't open file: $!.";
########    open (my $fastqFH_Abyss, ">", "$fileToRename" . "_Abyss") || die "Couldn't open file: $!";
########    while (my $line = <$fastqFH>) {
########        if ($line =~ /\s\d:N:\d:\d$/) {
########        $line =~ s/\s\d:N:\d:\d$/\/1/;
########        }
########        print $fastqFH_Abyss $line;
########    }
########    close ($fastqFH);
########    close ($fastqFH_Abyss);
########}
########
#########So we now have three output files:
########my $abyssPE1 = $noHumanNoEColiOut1 . "_Abyss";
########my $abyssPE2 = $noHumanNoEColiOut2 . "_Abyss";
########my $abyssSE = $joinedQCed . "_Abyss";
########
########
########print "***** Running de novo assembly of reads using multiple kmer and c and e values in Abyss *****.\n";
########
########my @abysskmer = qw(21 31 41 51 61);
########my @cevalue = qw(10 20);
########
########foreach my $kmer (@abysskmer) {
########    foreach my $ce (@cevalue) {
########        print "***** Running Abyss for $sampleID reads at kmer = $kmer and c and e both = $ce *****\n\n";
########        my $outfile = $sampleID . "_kmer" . $kmer . "_ce" . $ce;
########        print "Command = abyss-pe name=$pipeDir/data/ABYSS/$outfile k=$kmer c=$ce e=$ce in='$pipeDir/data/clean_data/$abyssPE1 $pipeDir/data/clean_data/$abyssPE2' se='$pipeDir/data/clean_data/$abyssSE'\n\n";
########        system("abyss-pe np=4 name=$pipeDir/data/ABYSS/$outfile k=$kmer c=$ce e=$ce in='$pipeDir/data/clean_data/$abyssPE1 $pipeDir/data/clean_data/$abyssPE2' se='$pipeDir/data/clean_data/$abyssSE'");
########        print "***** Finished running Abyss for $sampleID reads at kmer = $kmer and c and e both = $ce *****\n\n\n"
########    }
########}

#Code below by Mark shows how he cleans up extraneous files
####foreach my $kmer (@abysskmer) {
####	foreach my $cevalue (@cevalue) {
####		my $out = $name . "_kmer" . $kmer . "_ce" . $cevalue;
####		system ("abyss-pe mpirun='/home/analysis/bin/mpirun --hostfile /home/analysis/Desktop/hostfile' np=12 k=$kmer n=10 E=0 c=$cevalue e=$cevalue in='$read1 $read2' se='$unpaired' name=$dir/$out");
####		system("rm $dir/*.adj");
####		system("rm $dir/*path*");
####		system("rm $dir/*.dot");
####		#system("mv $dir/*contigs* $dir/contig");
####		#system("mv $dir/*stats $dir/contig");
####		#system("mv $dir/*-6.fa $dir/contig");
####		system("rm $dir/*.hist");
####		#system("rm $dir/*.fa");
####		system("rm $dir/*.dist");	
####	}
####}

