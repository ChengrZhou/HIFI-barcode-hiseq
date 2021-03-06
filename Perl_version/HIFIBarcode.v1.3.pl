#!/usr/bin/perl -w
#===============================================================================#
#---------------------------help-info-start-------------------------------------#
=head1 Description

	HIFIBarcode is used to produce full-length COI barcodes from pooled PCR 
	amplicons generated by individual specimens.

=head1 Usage
		
	perl  HIFIBarcode.v1.3.pl  
	--fq1    <str>  fastq 1
	--fq2    <str>  fastq 2
	--index  <str>  primer set with index ahead, format in "ID \t seq".
	--length <num>  length of index. default "0".
	--cpunum [num]  number of CPU. default "10".
	--outdir [str]  setting output directory. default "./".
	--outpre [str]  prefix of the output file. default "out".		
 	--help          print this help to screen.
	
=head1 Version
		
	Version :  1.3
	Created :  2017.7

=head1 Contact
    Author: Shanlin Liu, liushanlin@genomics.cn
            Chengran Zhou, zhouchengran@genomics.cn
    Publication: S. Liu, C. Yang, C. Zhou, X Zhou, Filling reference gaps 
	             via assembling DNA barcodes using ihigh-throughput
                 sequencing - moving toward to barcoding the world. 

=cut
#---------------------------help-info-end---------------------------------------#
#===============================================================================#

use strict;
use warnings;
use FindBin qw($Bin);
#use File::Basename;

my ($help,$fq1,$fq2,$index,$length,$cpu,$outdir,$outpre);
use Getopt::Long;
GetOptions(
	"fq1=s"		=> \$fq1,
	"fq2=s"		=> \$fq2,
	"index=s"	=> \$index,
	"length=s"	=> \$length,
	"cpunum:s"	=> \$cpu,
	"outdir:s"	=> \$outdir,
	"outpre:s"	=> \$outpre,
	"help:s"    => \$help,
	);

die `pod2text $0` if ($help );
die `pod2text $0` unless (defined $fq1 && defined $fq2 && defined $index && defined $length);

#============================================================================#
#                              Global Variable                               #
#============================================================================#
$cpu    ||= 10;
$outdir ||= "./";
$outpre ||= "out";
my $bindir="$Bin/bin";

#============================================================================#
#                               Main process                                 #
#============================================================================#
mkdir $outdir unless (-d $outdir);
for (my $i=1; $i<6;$i++){
	mkdir "$outdir/step$i" unless (-d "$outdir/step$i");
}

my $sh;
$sh="\#step 1 sorting clean reads\n";
$sh.="perl $bindir/1_split_extract.pl -fq1 $fq1  -fq2 $fq2  -pri $index -len $length -out $outdir/step1/$outpre\n";

$sh.="\#step 2 clustering\n";
$sh.="perl $bindir/2_uniqu_sort_cluster.Pro.pl  $outdir/step1/$outpre.splitlist $outdir/step2  $outpre\n";

$sh.="\#step 3 pairing\n";
$sh.="perl $bindir/3_sep_extract_overlap.pl  $outdir/step2/lis/$outpre.2lis $fq1 $fq2  $outdir/step3\n";

$sh.="\#step 4 trimming\n";
$sh.="perl $bindir/4_cluster_fromend.pl  $outdir/step3/lis/03overfas.lis  $outdir/step4\n";

$sh.="\#step 5 gap filling\n";
$sh.="perl $bindir/5_forgap_filling.pl  $outdir/step4/ends/rawends.fas  $outpre  $outdir/step5 $cpu\n";
$sh.="sh $outdir/final.sh\n";

open (OT,">","$outdir/runHIFIBarcode.sh");
print OT $sh;
close OT;

print "\nPlease sh $outdir/runHIFIBarcode.sh\n";  


