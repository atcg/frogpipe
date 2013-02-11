#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $fastq1;
my $fastq2;
my $fastq3;
my $fastq4;

GetOptions ( "f=s" => \$fastq1,
             "r=s" => \$fastq2,
             "s=s" => \$fastq3,
             "s2=s" => \$fastq4);

open (my $fastq1FH, "<", "$fastq1") || die "Couldn't open file: $!.";
open (my $fastq1_Abyss, ">", "$fastq1" . "_Abyss") || die "Couldn't open file: $!";
while (my $line = <$fastq1FH>) {
    if ($line =~ /\s\d:N:\d:\d$/) {
    $line =~ s/\s\d:N:\d:\d$/\/1/;
    }
    print $fastq1_Abyss $line;
}
close ($fastq1FH);
close ($fastq1_Abyss);

open (my $fastq2FH, "<", "$fastq2") || die "Couldn't open file: $!.";
open (my $fastq2_Abyss, ">", "$fastq2" . "_Abyss") || die "Couldn't open file: $!";
while (my $line = <$fastq2FH>) {
    if ($line =~ /\s\d:N:\d:\d$/) {
    $line =~ s/\s\d:N:\d:\d$/\/2/;
    }
    print $fastq2_Abyss $line;
}
close ($fastq2FH);
close ($fastq2_Abyss);

open (my $fastq3FH, "<", "$fastq3") || die "Couldn't open file: $!.";
open (my $fastq3_Abyss, ">", "$fastq3" . "_Abyss");
while (my $line = <$fastq3FH>) {
    if ($line =~ /\s\d:N:\d:\d$/) {
    $line =~ s/\s\d:N:\d:\d$/\/1/;
    }
    print $fastq3_Abyss $line;
}
close ($fastq3FH);
close ($fastq3_Abyss);

open (my $fastq4FH, "<", "$fastq4") || die "Couldn't open file: $!.";
open (my $fastq4_Abyss, ">", "$fastq4" . "_Abyss");
while (my $line = <$fastq4FH>) {
    if ($line =~ /\s\d:N:\d:\d$/) {
    $line =~ s/\s\d:N:\d:\d$/\/1/;
    }
    print $fastq4_Abyss $line;
}
close ($fastq4FH);
close ($fastq4_Abyss);

