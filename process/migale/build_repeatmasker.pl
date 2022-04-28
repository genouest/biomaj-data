#!/usr/bin/perl

use warnings;
use diagnostics;
use strict;
use Data::Dumper;

use Getopt::Long;
Getopt::Long::Configure( 'no_ignorecase' );

use lib ("$ENV{BIOMAJ_ROOT}/conf/process");
use MigaleBiomaj;
use File::Basename;
use File::Spec;
use Date::Format;
use File::Glob;

#variables communes aux scripts
my ( $help, $error, $debug );
my ( %h_pattern, %h_job_args );
my ( @t_job_args, @t_jobid_session, @t_task_args );
$h_job_args{biomaj} = 0;

#variables specifiques a ce script

#Constantes
my $VERSION = '0.5';

&MigaleBiomaj::read_config( \%h_job_args, 'repeatmasker' );

GetOptions (
#standard qualifiers
	    'outinput=s'        =>\$h_job_args{source_pattern},
#biomaj qualifiers
	    'biomaj'	        =>\$h_job_args{biomaj},
#standalone qualifiers
	    'outdir=s'          =>\$h_job_args{index_dir},
	    'indir=s'           =>\$h_job_args{source_dir},
#optional qualifiers
	    'execute=s'         =>\$h_job_args{batch_system},
	    'inname=s'           =>\$h_job_args{source_name},
	    'outname=s'          =>\$h_job_args{index_name},
#other qualifiers
	    'debug'             =>\$debug,
	    'help'              =>\$help,
	    'version'           =>sub{ print "version : $VERSION\n"; exit -1},
#repeatmasker qualifiers
	    'engine=s'          =>\$h_job_args{engine},
	    'parallel|pa=i'     =>\$h_job_args{parallel},
	    's'                 =>\$h_job_args{slow},
	    'q'                 =>\$h_job_args{quick},
	    'qq'                =>\$h_job_args{double_quick},
	    'low!'              =>\$h_job_args{low_complexity},
	    'int!'              =>\$h_job_args{interspersed_repeat},
	    'norna'             =>\$h_job_args{small_rna},
	    'alu'               =>\$h_job_args{alu},
	    'div=f'             =>\$h_job_args{repeat_divergence_threshold},
	    'lib=s'             =>\$h_job_args{custom_lib},
	    'cutoff=i'          =>\$h_job_args{cutoff_score},
	    'is_only'           =>\$h_job_args{clip_ecoli_is},
	    'is_clip'           =>\$h_job_args{clip_is_before},
	    'no_is'             =>\$h_job_args{skip_bact_is_check},
	    'rodspec'           =>\$h_job_args{check_rodent_repeat},
	    'primspec'          =>\$h_job_args{check_primate_repeat},
	    'gc=f'              =>\$h_job_args{background_gc_level},
	    'gccalc'            =>\$h_job_args{gc_calc},
	    'frag=i'            =>\$h_job_args{fragmentation_threshold},
	    'maxsize=s'         =>\$h_job_args{clip_threshold},
	    'nocut'             =>\$h_job_args{cut_stage},
	    'noisy'             =>\$h_job_args{verbose},
	    'nopost'            =>\$h_job_args{postprocess},
	    'alignments|a'      =>\$h_job_args{write_alignment},
	    'inv'               =>\$h_job_args{oriented_alignment},
	    'lcambig'           =>\$h_job_args{ambigous_fragment},
	    'small'             =>\$h_job_args{lowercase_mask},
	    'xsmall'            =>\$h_job_args{lowercase_repeat},
	    'x'                 =>\$h_job_args{X_mask},
	    'poly'              =>\$h_job_args{polymorphic_repeat},
	    'ace'               =>\$h_job_args{acebd_format},
	    'gff'               =>\$h_job_args{gff_format},
	    'u'                 =>\$h_job_args{raw_annotation},
	    'xm'                =>\$h_job_args{crossmatch_format},
	    'fixed'             =>\$h_job_args{fixed_column},
	    'no_id'             =>\$h_job_args{id_foreach},
	    'e'                 =>\$h_job_args{repeat_density},
	    );


#recuperation de la configuration
 INITITATION: {
     &usage() if ($help);
 
     &error('outinput requiered') if( !defined($h_job_args{source_pattern}) || ($h_job_args{source_pattern} eq '') );
 }


 ENVIRONMENT:{
#mise en place de l'environnement dans une session BioMaJ
     if( $h_job_args{biomaj} ) {
	 &info('Load : BioMaJ Environment.');
	 &MigaleBiomaj::biomaj_environment( \%h_job_args );
     }

#mise en place de l'environnement dans une session Standalone
     elsif( ( defined $h_job_args{source_dir} ) && ( defined $h_job_args{index_dir} ) ) {
	 &info('Load : StandAlone Environment.');
	 &MigaleBiomaj::standalone_environment( \%h_job_args );
     }

#probleme donc sortie en usage()
     else {
	 &usage();
     }

#mise en place commune aux deux modes d'execution
     &MigaleBiomaj::make_directory($h_job_args{index_dir});
     chdir $h_job_args{index_dir};

     &MigaleBiomaj::drmaa_initiation() if( $h_job_args{batch_system} eq 'drmaa' );
     &MigaleBiomaj::make_directory($h_job_args{log_dir});

#parse la ligne de commande outinput et cree un hash     
     &MigaleBiomaj::string2hash($h_job_args{source_pattern},\%h_pattern);
 }


 ARGUMENTS:{
     @t_job_args = ( '-dir', $h_job_args{index_dir} );

     @t_job_args = ( @t_job_args, '-s' )        if( defined $h_job_args{slow} );
     @t_job_args = ( @t_job_args, '-q' )        if( defined $h_job_args{quick} );
     @t_job_args = ( @t_job_args, '-qq' )       if( defined $h_job_args{double_quick} );
     @t_job_args = ( @t_job_args, '-norna' )    if( defined $h_job_args{small_rna} );
     @t_job_args = ( @t_job_args, '-alu' )      if( defined $h_job_args{alu} );
     @t_job_args = ( @t_job_args, '-low' )      if( (defined $h_job_args{low_complexity}) && ($h_job_args{low_complexity}) );
     @t_job_args = ( @t_job_args, '-nolow' )    if( (defined $h_job_args{low_complexity}) && !($h_job_args{low_complexity}) );
     @t_job_args = ( @t_job_args, '-int' )      if( (defined $h_job_args{interspersed_repeat}) && ($h_job_args{interspersed_repeat}) );
     @t_job_args = ( @t_job_args, '-noint' )    if( (defined $h_job_args{interspersed_repeat}) && !($h_job_args{interspersed_repeat}) );

     @t_job_args = ( @t_job_args, '-engine', $h_job_args{engine} )                   if( defined $h_job_args{engine} );
     @t_job_args = ( @t_job_args, '-div', $h_job_args{repeat_divergence_threshold} ) if( defined $h_job_args{repeat_divergence_threshold} );
     @t_job_args = ( @t_job_args, '-lib', $h_job_args{custom_lib} )                  if( defined $h_job_args{custom_lib} );
     @t_job_args = ( @t_job_args, '-cutoff', $h_job_args{cutoff_score} )             if( defined $h_job_args{cutoff_score} );
     
     @t_job_args = ( @t_job_args, '-is_only' )   if( defined $h_job_args{clip_ecoli_is} );
     @t_job_args = ( @t_job_args, '-is_clip' )   if( defined $h_job_args{clip_is_before} );
     @t_job_args = ( @t_job_args, '-no_is' )     if( defined $h_job_args{skip_bact_is_check} );
     @t_job_args = ( @t_job_args, '-rodspec' )   if( defined $h_job_args{check_rodent_repeat} );
     @t_job_args = ( @t_job_args, '-primspec' )  if( defined $h_job_args{check_primate_repeat} );
     
     @t_job_args = ( @t_job_args, '-gccalc' )    if( defined $h_job_args{gc_calc} );
     @t_job_args = ( @t_job_args, '-nocut' )     if( defined $h_job_args{cut_stage} );
     @t_job_args = ( @t_job_args, '-noisy' )     if( defined $h_job_args{verbose} );
     @t_job_args = ( @t_job_args, '-nopost' )    if( defined $h_job_args{postprocess} );

     @t_job_args = ( @t_job_args, '-frag', $h_job_args{fragmentation_threshold} )    if( defined $h_job_args{fragmentation_threshold} );
     @t_job_args = ( @t_job_args, '-maxsize', $h_job_args{clip_threshold} )          if( defined $h_job_args{clip_threshold} );
     @t_job_args = ( @t_job_args, '-gc', $h_job_args{background_gc_level} )          if( defined $h_job_args{background_gc_level} );
     
     @t_job_args = ( @t_job_args, '-alignments' ) if( defined $h_job_args{write_alignment} );
     @t_job_args = ( @t_job_args, '-inv' )        if( defined $h_job_args{oriented_alignment} );
     @t_job_args = ( @t_job_args, '-lcambig' )    if( defined $h_job_args{ambigous_fragment} );
     @t_job_args = ( @t_job_args, '-small' )      if( defined $h_job_args{lowercase_mask} );
     @t_job_args = ( @t_job_args, '-xsmall' )     if( defined $h_job_args{lowercase_repeat} );
     @t_job_args = ( @t_job_args, '-x' )          if( defined $h_job_args{X_mask} );
     @t_job_args = ( @t_job_args, '-poly' )       if( defined $h_job_args{polymorphic_repeat} );
     @t_job_args = ( @t_job_args, '-ace' )        if( defined $h_job_args{acebd_format} );
     @t_job_args = ( @t_job_args, '-gff' )        if( defined $h_job_args{gff_format} );
     @t_job_args = ( @t_job_args, '-u' )          if( defined $h_job_args{raw_annotation} );
     @t_job_args = ( @t_job_args, '-xm' )         if( defined $h_job_args{crossmatch_format} );
     @t_job_args = ( @t_job_args, '-fixed' )      if( defined $h_job_args{fixed_column} );
     @t_job_args = ( @t_job_args, '-no_id' )      if( defined $h_job_args{id_foreach} );
     @t_job_args = ( @t_job_args, '-e' )          if( defined $h_job_args{repeat_density} );

     $h_job_args{remote_command} =  $h_job_args{binary_path}.'/'. $h_job_args{repeatmasker};
 }

#index
 MAIN: {
     my ( $species, $file );
     my ( %h_files );
     my ( @t_files );

     &MigaleBiomaj::select_file($h_job_args{source_dir}, \%h_pattern, \%h_files);
     print Dumper(%h_files);

     while( ($species, $file) = each(%h_files) ) {
	 &debug('Variable>%h_files : '.$species.' = '.$file) if($debug);
	 
	 chop $file;
	 @t_files = split ' ', $file;

	 for( @t_files ) {
	     
	     @t_task_args = ( @t_job_args, '-species', $species, $_ );
	     
	     $h_job_args{argv} = \@t_task_args;
	     $h_job_args{job_name} = $h_job_args{index_name}.'.'.basename($_);
	     
	     push( @t_jobid_session, &MigaleBiomaj::execution_factory(\%h_job_args) );
	     &info('');
	 }
     }
     &MigaleBiomaj::drmaa_synchronization( \@t_jobid_session )                          if( $h_job_args{batch_system} eq 'drmaa' );
     &MigaleBiomaj::output_file( $h_job_args{index_dir}, \%h_pattern, 'dependence', 1 ) if( $h_job_args{biomaj} );
     &MigaleBiomaj::print_output_files()                                                if( $h_job_args{biomaj} );
     exit 0;
 }
exit 1;

sub usage() {

print <<"USAGE";

build_gcgblast.pl version $VERSION

Standard qualifiers:
  -outinput       Association between output and input. [species=pattern_in]
                  <species>=<filename>,[<speciesN_dbnameN=filenameN>]

BioMaJ qualifiers:
  -biomaj         Execution in BioMaJ session. [Boolean] 
                  default = 0, standalone

Standalone qualifiers:        
  -outdir         Directory of output files. [Directory Path]
                  Requiered in standalone mode
  -indir          Directory of input files. [Directory Path]
                  Requiered in standalone mode
 
Optional qualifiers:
  -execute        Execution mode. [local|drmaa|debug]
                  default = in migale_biomaj.cfg
  -inname         Name of the input directory in the databank directory. [string] Optional
                  Only in BioMaJ session
                  default = source_name in migale_biomaj.cfg
  -outname        Name of the output directory in the databank directory. [string] Optional
                  Only in BioMaJ session
                  default = index_name in migale_biomaj.cfg

Other qualifiers:
  -help           Display this message. [boolean]
  -debug          Display debug messages. [boolean]
                  default = in migale_biomaj.cfg
  -version        Display program version. [boolean]

RepeatMasker qualifiers:
  -engine         Use an alternate search engine to the default. [crossmatch|wublast|decypher]
                  default = crossmatch
  -pa(rallel)     The number of processors to use in parallel. [number]
                  default = 1
  -s              Slow search; 0-5% more sensitive, 2-3 times slower than default.
  -q              Quick search; 5-10% less sensitive, 2-5 times faster than default.
  -qq             Rush job; about 10% less sensitive, 4->10 times faster than default.
                  (quick searches are fine under most circumstances) repeat options
  -nolow /-low    Does not mask low_complexity DNA or simple repeats.
  -noint /-int    Only masks low complex/simple repeats (no interspersed repeats).
  -norna          Does not mask small RNA (pseudo) genes.
  -alu            Only masks Alus (and 7SLRNA, SVA and LTR5)(only for primate DNA)
  -div            Masks only those repeats < x percent diverged from consensus seq. [number]
  -lib            Allows use of a custom library (e.g. from another species). [filename]
  -cutoff         Sets cutoff score for masking repeats when using -lib (default 225). [number]
  -species        Specify the species or clade of the input sequence. <query species>
                  The species name must be a valid NCBI Taxonomy Database species name and be contained
		  in the RepeatMasker repeat database. Some examples are:
		     -species human
		     -species mouse
		     -species rattus
		     -species "ciona savignyi"
		     -species arabidopsis
		  Other commonly used species:
		     mammal, carnivore, rodentia, rat, cow, pig, cat, dog, chicken, fugu,
		     danio, "ciona intestinalis" drosophila, anopheles, elegans,
		     diatoaea, artiodactyl, arabidopsis, rice, wheat, and maize

Contamination options
  -is_only        Only clips E coli insertion elements out of fasta and .qual files
  -is_clip        Clips IS elements before analysis (default: IS only reported)
  -no_is          Skips bacterial insertion element check
  -rodspec        Only checks for rodent specific repeats (no repeatmasker run)
  -primspec       Only checks for primate specific repeats (no repeatmasker run)

Running options
  -gc             Use matrices calculated for 'number' percentage background GC level. [number]
  -gccalc         RepeatMasker calculates the GC content even for batch files/small seqs.
  -frag           Maximum sequence length masked without fragmenting. [number]
                  default = 40000
		  DeCypher default = 300000
  -maxsize        Maximum length for which IS- or repeat clipped sequences can be produced. [nr]
                  Memory requirements go up with higher maxsize.
                  default = 4000000
  -nocut          Skips the steps in which repeats are excised
  -noisy          Prints search engine progress report to screen (defaults to .stderr file)
  -nopost         Do not postprocess the results of the run.
                  i.e. call ProcessRepeats
		  NOTE: This options should only be used when ProcessRepeats will be run manually on the results.

output options
  -dir            Writes output to this directory. [directory name]
                  default is query file directory.
  -a(lignments)   Writes alignments in .align output file; (not working with -wublast)
  -inv            Alignments are presented in the orientation of the repeat (with option -a)
  -lcambig        Outputs ambiguous DNA transposon fragments using a lower case name.
                  All other repeats are listed in upper case. Ambiguous fragments
                  match multiple repeat elements and can only be called based on
                  flanking repeat information.
  -small          Returns complete .masked sequence in lower case
  -xsmall         Returns repetitive regions in lowercase (rest capitals) rather than masked
  -x              Returns repetitive regions masked with Xs rather than Ns
  -poly           Reports simple repeats that may be polymorphic (in file.poly)
  -ace            Creates an additional output file in ACeDB format
  -gff            Creates an additional Gene Feature Finding format output
  -u              Creates an additional annotation file not processed by ProcessRepeats
  -xm             Creates an additional output file in cross_match format (for parsing)
  -fixed          Creates an (old style) annotation file with fixed width columns
  -no_id          Leaves out final column with unique ID for each element (was default)
  -e(xcln)        Calculates repeat densities (in .tbl) excluding runs of >=20 N/Xs in the query

USAGE
   
    exit -1;
}

__END__

=pod

=head1 NAME

B<build_gcg.pl> - Script permettant de masquer les repetitions au sein d'une sequence ADN.

=head1 VERSION

Version 0.5 (December 2007)

=head1 USAGE

=head2 Traitement RepeatMasker pour le genome Human

=head3 Session BioMaJ

C<build_repeatmasker.pl --biomaj --outinput human=*dna.chromosome.fasta -s>

=head3 Session Standalone

C<build_repeatmasker.pl --outdir /db/human/repeatmasker/ --indir /db/human/fasta/ --outinput human=*.dna.chromosome.fasta -s>

=head1 DESCRIPTION

=over

=item - Gestion des options de RepeatMasker

=item - Differente possibilite d'execution

=item - traitement a partir d'un lot de fichiers via les caracteres joker (*).

=back

=head1 REQUIRED ARGUMENTS

Standard qualifiers:
  -outinput       Association between output and input. [species=pattern_in]
                  <species>=<filename>,[<speciesN_dbnameN=filenameN>]

BioMaJ qualifiers:
  -biomaj         Execution in BioMaJ session. [Boolean] 
                  default = 0, standalone

Standalone qualifiers:        
  -outdir         Directory of output files. [Directory Path]
                  Requiered in standalone mode
  -indir          Directory of input files. [Directory Path]
                  Requiered in standalone mode

=head1 OPTIONS

Optional qualifiers:
  -execute        Execution mode. [local|drmaa|debug]
                  default = in migale_biomaj.cfg
  -inname         Name of the input directory in the databank directory. [string] Optional
                  Only in BioMaJ session
                  default = source_name in migale_biomaj.cfg
  -outname        Name of the output directory in the databank directory. [string] Optional
                  Only in BioMaJ session
                  default = index_name in migale_biomaj.cfg

Other qualifiers:
  -help           Display this message. [boolean]
  -debug          Display debug messages. [boolean]
                  default = in migale_biomaj.cfg
  -version        Display program version. [boolean]

RepeatMasker qualifiers:
  -engine         Use an alternate search engine to the default. [crossmatch|wublast|decypher]
                  default = crossmatch
  -pa(rallel)     The number of processors to use in parallel. [number]
                  default = 1
  -s              Slow search; 0-5% more sensitive, 2-3 times slower than default.
  -q              Quick search; 5-10% less sensitive, 2-5 times faster than default.
  -qq             Rush job; about 10% less sensitive, 4->10 times faster than default.
                  (quick searches are fine under most circumstances) repeat options
  -nolow /-low    Does not mask low_complexity DNA or simple repeats.
  -noint /-int    Only masks low complex/simple repeats (no interspersed repeats).
  -norna          Does not mask small RNA (pseudo) genes.
  -alu            Only masks Alus (and 7SLRNA, SVA and LTR5)(only for primate DNA)
  -div            Masks only those repeats < x percent diverged from consensus seq. [number]
  -lib            Allows use of a custom library (e.g. from another species). [filename]
  -cutoff         Sets cutoff score for masking repeats when using -lib (default 225). [number]
  -species        Specify the species or clade of the input sequence. <query species>
                  The species name must be a valid NCBI Taxonomy Database species name and be contained
                  in the RepeatMasker repeat database. Some examples are:
                    -species human
                    -species mouse
                    -species rattus
                    -species "ciona savignyi"
                    -species arabidopsis
                  Other commonly used species:mammal, carnivore, rodentia, rat, cow, pig, cat, dog, chicken, fugu,
                  danio, "ciona intestinalis" drosophila, anopheles, elegans,diatoaea, artiodactyl, arabidopsis,
                  rice, wheat, and maize

Contamination options
  -is_only        Only clips E coli insertion elements out of fasta and .qual files
  -is_clip        Clips IS elements before analysis (default: IS only reported)
  -no_is          Skips bacterial insertion element check
  -rodspec        Only checks for rodent specific repeats (no repeatmasker run)
  -primspec       Only checks for primate specific repeats (no repeatmasker run)

Running options
  -gc             Use matrices calculated for 'number' percentage background GC level. [number]
  -gccalc         RepeatMasker calculates the GC content even for batch files/small seqs.
  -frag           Maximum sequence length masked without fragmenting. [number]
                  default = 40000
                  DeCypher default = 300000
  -maxsize        Maximum length for which IS- or repeat clipped sequences can be produced. [nr]
                  Memory requirements go up with higher maxsize.
                  default = 4000000
  -nocut          Skips the steps in which repeats are excised
  -noisy          Prints search engine progress report to screen (defaults to .stderr file)
  -nopost         Do not postprocess the results of the run.
                  i.e. call ProcessRepeats
                  NOTE: This options should only be used when ProcessRepeats will be run manually on the results.

output options
  -dir            Writes output to this directory. [directory name]
                  default is query file directory.
  -a(lignments)   Writes alignments in .align output file; (not working with -wublast)
  -inv            Alignments are presented in the orientation of the repeat (with option -a)
  -lcambig        Outputs ambiguous DNA transposon fragments using a lower case name.
                  All other repeats are listed in upper case. Ambiguous fragments
                  match multiple repeat elements and can only be called based on
                  flanking repeat information.
  -small          Returns complete .masked sequence in lower case
  -xsmall         Returns repetitive regions in lowercase (rest capitals) rather than masked
  -x              Returns repetitive regions masked with Xs rather than Ns
  -poly           Reports simple repeats that may be polymorphic (in file.poly)
  -ace            Creates an additional output file in ACeDB format
  -gff            Creates an additional Gene Feature Finding format output
  -u              Creates an additional annotation file not processed by ProcessRepeats
  -xm             Creates an additional output file in cross_match format (for parsing)
  -fixed          Creates an (old style) annotation file with fixed width columns
  -no_id          Leaves out final column with unique ID for each element (was default)
  -e(xcln)        Calculates repeat densities (in .tbl) excluding runs of >=20 N/Xs in the query

=head1 EXIT STATUS

Exit E<gt>0 : erreur lors de l'indexation

=head1 CONFIGURATION

=head2 Fichier de configuration

C<migale_biomaj.cfg> dans le repertoire conf/process/

=head2 Section [repeatmasker]

=head3 Obligatoire

index_name : nom du repertoire stockant les fichiers traites par RepeatMasker

source_name : nom du repertoire stockant les fichiers necessaires a Repeatmasker

binary_path : chemin absolue du repertoire contenant les binaires

repeatmasker : nom du binaire de RepeatMasker

=head3 Optionnel

batch_system : mode d'execution specifique a RepeatMasker

cluster_option : option du cluster specifique a RepeatMasker

=head1 DEPENDENCIES

=head2 Modules Perl

warnings, diagnostics, strict

Getopt::Long, MigaleBiomaj, File::Basename

=head2 Programmes exterieurs

=over

=item GCG 11

=back

=head1 BUGS AND LIMITATIONS

=over

=item - Le module DRMAAc n'a ete teste que sur le scheduler SGE.

=item - La suite GCG n'a pas ete teste sur le cluster

=item - L'initiation de GCG via les scripts posent probleme, il est preferable d'initialiser avant l'utilisation.

=back

=head1 AUTHOR

Ludovic Legrand L<ludovic.legrand@jouy.inra.fr>

=head1 LICENSE AND COPYRIGHT

Copyright 2007 INRA MIG, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

