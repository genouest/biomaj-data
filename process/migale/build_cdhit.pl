#!/usr/bin/perl

use warnings;
use diagnostics;
use strict;

use Getopt::Long;
Getopt::Long::Configure( 'no_ignorecase' );

use lib ("$ENV{BIOMAJ_ROOT}/conf/process");
use MigaleBiomaj;
use File::Basename;

#use Data::Dumper;
#use File::Spec;
#use Date::Format;
#use File::Glob;

#variables communes aux scripts
my ( $help, $error, $debug );
my ( %h_pattern, %h_job_args );
my ( @t_job_args );
$h_job_args{biomaj} = 0;

#variables specifiques a ce script

#Constantes
my $VERSION = '0.5';

&MigaleBiomaj::read_config( \%h_job_args, 'cdhit' );

GetOptions (
#standard qualifiers
	    'outinput=s'         =>\$h_job_args{source_pattern},
	    'memory|M=i'         =>\$h_job_args{memory},
	    'threshold|c=f'      =>\$h_job_args{identity_threshold},
	    
#standalone qualifiers   
	    'indir=s'            =>\$h_job_args{source_dir},
	    'outdir=s'           =>\$h_job_args{index_dir},
#biomaj qualifiers   
	    'biomaj'             =>\$h_job_args{biomaj},
#optional qualifiers	    
	    'execute=s'          =>\$h_job_args{batch_system},
	    'inname=s'           =>\$h_job_args{source_name},
	    'outname=s'          =>\$h_job_args{index_name},
#other qualifiers
	    'debug'              =>\$debug,
	    'help|h'             =>\$help,
	    'version'            =>sub{ print "version : $VERSION\n"; exit -1 },
#cdhit qualifiers
	    'n=i'                =>\$h_job_args{word_length},
	    'G'                  =>\$h_job_args{global_seq_identity},
	    'b=i'                =>\$h_job_args{bandwidth_alignment},
	    'l=i'                =>\$h_job_args{throw_away_lenght},
	    't=i'                =>\$h_job_args{redundance_tolerance},
	    'd=i'                =>\$h_job_args{clstr_desc_length},
	    's=f'                =>\$h_job_args{length_difference_cutoff},
	    'S=i'                =>\$h_job_args{aa_length_difference_cutoff},
	    'aL=f'               =>\$h_job_args{long_alignment_coverage},
	    'AL=i'               =>\$h_job_args{long_alignment_control},
	    'aS=f'               =>\$h_job_args{short_alignment_coverage},
	    'AS=i'               =>\$h_job_args{short_alignment_control},
	    'B'                  =>\$h_job_args{sequence_in_ram},
	    'p'                  =>\$h_job_args{print_alignment_overlap},
	    'g'                  =>\$h_job_args{cluster_algorithm}, 
	    );


#recuperation de la configuration
 INITIATION: {
     &usage() if ($help);
     
     &error('-outinput requiered')  if( &is_null($h_job_args{source_pattern}) );
     &error('-memory|M requiered')    if( &is_null($h_job_args{memory}) );
     &error('-threshold|c requiered') if( &is_null($h_job_args{identity_threshold}) );
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

#calcul automatiquement le word_length en fonction du threshold 
     &cdhit_word_length();
#parse la ligne de commande outinput et cree un hash     
     &MigaleBiomaj::string2hash($h_job_args{source_pattern},\%h_pattern);
 }

#positionne les arguments constants lors du job
 ARGUMENTS:{
     @t_job_args = ( '-n', $h_job_args{word_length}, '-c', $h_job_args{identity_threshold}, '-M', $h_job_args{memory} );
#valeurs
     @t_job_args = ( @t_job_args, '-l', $h_job_args{throw_away_lenght} )           if( defined $h_job_args{throw_away_lenght} );
     @t_job_args = ( @t_job_args, '-b', $h_job_args{bandwidth_alignment} )         if( defined $h_job_args{bandwidth_alignment} );
     @t_job_args = ( @t_job_args, '-s', $h_job_args{length_difference_cutoff} )    if( defined $h_job_args{length_difference_cutoff} );
     @t_job_args = ( @t_job_args, '-d', $h_job_args{clstr_desc_length} )           if( defined $h_job_args{clstr_desc_length} );
     @t_job_args = ( @t_job_args, '-aL', $h_job_args{long_alignment_coverage} )    if( defined $h_job_args{long_alignment_coverage} );
     @t_job_args = ( @t_job_args, '-S', $h_job_args{aa_length_difference_cutoff} ) if( defined $h_job_args{aa_length_difference_cutoff} );
     @t_job_args = ( @t_job_args, '-aS', $h_job_args{short_alignment_coverage} )   if( defined $h_job_args{short_alignment_coverage} );
     @t_job_args = ( @t_job_args, '-AL', $h_job_args{long_alignment_control} )     if( defined $h_job_args{long_alignment_control} );
     @t_job_args = ( @t_job_args, '-t', $h_job_args{redundance_tolerance} )        if( defined $h_job_args{redundance_tolerance} );
     @t_job_args = ( @t_job_args, '-AS', $h_job_args{short_alignment_control} )    if( defined $h_job_args{short_alignment_control} );
#booleen
     @t_job_args = ( @t_job_args, '-G', $h_job_args{global_seq_identity} )         if( $h_job_args{global_seq_identity} );
     @t_job_args = ( @t_job_args, '-B', $h_job_args{sequence_in_ram} )             if( $h_job_args{sequence_in_ram} );
     @t_job_args = ( @t_job_args, '-p', $h_job_args{print_alignment_overlap} )     if( $h_job_args{print_alignment_overlap} );
     @t_job_args = ( @t_job_args, '-g', $h_job_args{cluster_algorithm} )           if( $h_job_args{cluster_algorithm} );
     
     $h_job_args{remote_command} =  $h_job_args{binary_path}.'/'. $h_job_args{cdhit};
 }

#Indexation
MAIN: {
    my ( $index_file, $source_file );
    my ( @t_jobid_session, @t_task_args );

    while( ($index_file, $source_file) = each(%h_pattern) ) {
	&debug('Variable>%h_pattern : '.$index_file.' = '.$source_file) if($debug);

	@t_task_args = ( @t_job_args, '-i', $h_job_args{source_dir}.$source_file, '-o', $index_file );
	$h_job_args{argv} = \@t_task_args;
	$h_job_args{job_name} = $h_job_args{index_name}.'.'.$index_file;

	push( @t_jobid_session, &MigaleBiomaj::execution_factory(\%h_job_args) );
	&info('');
    }
    &MigaleBiomaj::drmaa_synchronization( \@t_jobid_session )                         if( $h_job_args{batch_system} eq 'drmaa' );
    &MigaleBiomaj::output_file($h_job_args{index_dir}, \%h_pattern, 'dependence', 1 ) if( $h_job_args{biomaj} );
    &MigaleBiomaj::print_output_files()                                               if( $h_job_args{biomaj} );
}


sub cdhit_word_length() {
    if( defined($h_job_args{word_length}) ) {
	return;
    }

  SWITCH:for( $h_job_args{identity_threshold} ) {
      /^[1]\.[0]+$/ && do {
	  $h_job_args{word_length} = 5;
	  last;
      };
      /^[0]\.[7-9][0-9]?$/ && do {
	  $h_job_args{word_length} = 5;
	  last;
      };
      /^[0]\.[6][0-9]?$/ && do {
	  $h_job_args{word_length} = 4;
	  last;
      };
      /^[0]\.[5][0-9]?$/ && do {
	  $h_job_args{word_length} = 3;
	  last;
      };
      /^[0]\.[4][0-9]?$/ && do {
	  $h_job_args{word_length} = 2;
	  last;
      };
      die 'Identity threshold < 4';
  }
}

sub usage() {
      print <<"EOF";
build_cdhit.pl version $VERSION

Standard qualifiers:
  -threshold|c    sequence identity threshold. This is the default cd-hit\'s global sequence identity calculated as :
                  number of identical amino acids in alignment divided by the full length of the shorter sequence
		  default = 0.9
  -outinput       Association between output and input. [filename_out=pattern_in]
                  nr90=nr.fasta
	          more information with : -help outinput
  -memory|M       max available memory (Mbyte). [integer]
                  Min = 512

BioMaJ qualifiers:
  -biomaj         Execution in BioMaJ session. [Booleen] 
                  default = 0, standalone
 -inname          Name of the input directory in the databank directory. [string] Optional
                  Only in BioMaJ session
                  default = source_name in migale_biomaj.cfg
  -outname        Name of the output directory in the databank directory. [string] Optional
                  Only in BioMaJ session
                  default = index_name in migale_biomaj.cfg
Standalone qualifiers:        
  -outdir         Directory of output files. [Directory Path] Requiered in Standalone session
  -indir          Directory of input files. [Directory Path] Requiered in Standalone session

Optional qualifiers:
  -execute        Execution mode. [local|drmaa|debug] Optional
                  default = local
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

Cd-hit qualifiers:

  -n      word length, automatically defined. [integer]
          5 : 0.7 < threshold < 1
          4 : 0.6 < threshold < 0.7
	  3 : 0.5 < threshold < 0.6
	  2 : 0.4 < threshold < 0.5
  -G      use global sequence identity. [boolean]
          If set to 0, then use local sequence identity, calculated as :
          number of identical amino acids in alignment divided by the length of the alignment.
	  NOTE!!! don\'t use -G 0 unless you use alignment coverage controls see options -aL, -AL, -aS, -AS
	  default = 0
  -b      band_width of alignment. [integer]
          default = 20
  -l      length of throw_away_sequences. [integer]
          default = 10
  -t      tolerance for redundance. [integer]
          default = 2
  -d      length of description in .clstr file. [integer]
          If set to 0, it takes the fasta defline and stops at first space.
	  default = 20
  -s      length difference cutoff. [float]
          If set to 0.9, the shorter sequences need to be at least 90% length of the representative of the cluster.
	  default = 0.0
  -S      length difference cutoff in amino acid. [integer]
          If set to 60, the length difference between the shorter sequences and the representative of the cluster can not be bigger than 60.
          default = 999999
  -aL     alignment coverage for the longer sequence. [float]
          If set to 0.9, the alignment must covers 90% of the sequence.
	  default = 0.0
  -AL     alignment coverage control for the longer sequence. [integer]
          If set to 60, and the length of the sequence is 400, then the alignment must be >= 340 (400-60) residues.
	  default = 99999999
  -aS     alignment coverage for the shorter sequence. [float]
          If set to 0.9, the alignment must covers 90% of the sequence.
	  default = 0.0
  -AS     alignment coverage control for the shorter sequence. [integer]
          If set to 60, and the length of the sequence is 400, then the alignment must be >= 340 (400-60) residues.
	  default = 99999999
  -B      sequences storage. [boolean]
          0 : sequence are stored in RAM
	  1 : sequence are stored on hard drive
	  default = 0
  -p      print alignment overlap in .clstr file. [boolean]
          0 : no print
	  1 : print
	  default = 0
  -g      cd-hit\'s default algorithm, a sequence is clustered to the first cluster that meet the threshold (fast cluster). [boolean]
          0 : default algorithm (fast)
	  1 : the program will cluster it into the most similar cluster that meet the threshold (slow)
	  but either 1 or 0 won\'t change the representatives of final clusters
	  default = 0

EOF
   exit -1;
}

__END__

=pod

=head1 NAME

B<build_cdhit.pl> - Script permettant de lancer des indexations CDHIT sur des banques de donnees soit a l'interieur d'une session BioMaJ soit de maniere independante.

=head1 VERSION

Version 0.5 (December 2007)

=head1 USAGE

=head2 Indexation de la banque NR

=head3 Session BioMaJ

S<build_cdhit.pl --biomaj --outinput nr=nr.fasta -p T>

=head3 Session Standalone

S<build_cdhit.pl --outdir /db/nr/cdhit/ --indir /db/nr/fasta/ --outinput nr=nr.fasta --dbname nr -p T>

=head1 DESCRIPTION

B<build_cdhit.pl> 

=head1 REQUIRED ARGUMENTS

=head2 Standard qualifiers

  -threshold|c    sequence identity threshold. This is the default cd-hit s global sequence identity calculated as :
                  number of identical amino acids in alignment divided by the full length of the shorter sequence
		  default = 0.9

  -outinput       Association between output and input. [filename_out=pattern_in]
                  nr90=nr.fasta
	          more information with : -help outinput

  -memory|M       max available memory (Mbyte). [integer]
                  Min = 512

=head2 BioMaJ qualifiers

  -biomaj         Execution in BioMaJ session. [Booleen] 
                  default = 0, standalone

=head2 Standalone qualifiers

  -outdir         Directory of output files. [Directory Path]
                  Requiered in Standalone session

  -indir          Directory of input files. [Directory Path]
                  Requiered in Standalone session

=head1 OPTIONS

Optional qualifiers:
  -execute        Execution mode. [local|drmaa|debug] Optional
                  default = local
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

Cd-hit qualifiers:

  -n      word length, automatically defined. [integer]
          5 : 0.7 < threshold < 1
          4 : 0.6 < threshold < 0.7
	  3 : 0.5 < threshold < 0.6
	  2 : 0.4 < threshold < 0.5
  -G      use global sequence identity. [boolean]
          If set to 0, then use local sequence identity, calculated as :
          number of identical amino acids in alignment divided by the length of the alignment.
	  NOTE!!! don\'t use -G 0 unless you use alignment coverage controls see options -aL, -AL, -aS, -AS
	  default = 0
  -b      band_width of alignment. [integer]
          default = 20
  -l      length of throw_away_sequences. [integer]
          default = 10
  -t      tolerance for redundance. [integer]
          default = 2
  -d      length of description in .clstr file. [integer]
          If set to 0, it takes the fasta defline and stops at first space.
	  default = 20
  -s      length difference cutoff. [float]
          If set to 0.9, the shorter sequences need to be at least 90% length of the representative of the cluster.
	  default = 0.0
  -S      length difference cutoff in amino acid. [integer]
          If set to 60, the length difference between the shorter sequences and the representative of the cluster can not be bigger than 60.
          default = 999999
  -aL     alignment coverage for the longer sequence. [float]
          If set to 0.9, the alignment must covers 90% of the sequence.
	  default = 0.0
  -AL     alignment coverage control for the longer sequence. [integer]
          If set to 60, and the length of the sequence is 400, then the alignment must be >= 340 (400-60) residues.
	  default = 99999999
  -aS     alignment coverage for the shorter sequencE. [float]
          If set to 0.9, the alignment must covers 90% of the sequence.
	  default = 0.0
  -AS     alignment coverage control for the shorter sequence. [integer]
          If set to 60, and the length of the sequence is 400, then the alignment must be >= 340 (400-60) residues.
	  default = 99999999
  -B      sequences storage. [boolean]
          0 : sequence are stored in RAM
	  1 : sequence are stored on hard drive
	  default = 0
  -p      print alignment overlap in .clstr file. [boolean]
          0 : no print
	  1 : print
	  default = 0
  -g      cd-hit\'s default algorithm, a sequence is clustered to the first cluster that meet the threshold (fast cluster). [boolean]
          0 : default algorithm (fast)
	  1 : the program will cluster it into the most similar cluster that meet the threshold (slow)
	  but either 1 or 0 won\'t change the representatives of final clusters
	  default = 0

=head1 EXIT STATUS

Exit  E<gt>0 : erreur lors de l'indexation

=head1 CONFIGURATION

Fichier de configuration : migale_biomaj.cfg

=head2 Section [cdhit]

=head3 Obligatoire

index_name : nom du repertoire ou seront entreposes les fichiers cdhit

source_name : nom du repertoire utilise pour generer les fichiers cdhit

binary_path : chemin absolu du repertoire des binaires cd-hit

cdhit : nom du programme cd-hit dans le repertoire binaires cd-hit

=head3 Optionnel

cluster_option : options du cluster specifiques a build_cdhit.pl

batch_system : type d'execution par defaut pour build_cdhit.pl

=head1 DEPENDENCIES

=head2 Modules Perl

warnings, diagnostics, strict

Getopt::Long, File::Basename

MigaleBiomaj

=head2 Programmes externes

=over

=item cd-hit

=back

=head1 BUGS AND LIMITATIONS

=over

=item - Le module DRMAAc n'a ete teste que sur le scheduler SGE.

=back

=head1 AUTHOR

Ludovic Legrand L<ludovic.legrand@jouy.inra.fr>

=head1 LICENSE AND COPYRIGHT

Copyright 2007 INRA MIG, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 Fonctions internes

=head2 cdhit_word_length

  Function    : cdhit_word_length()
  Description : Permet de selectionner la taille des mots en fonction de l'identity threshold. Cette table de correspondance est dans la doc du logiciel.
  Usage       : cdhit_word_length()
  Arguments   : none
  Return      : positionne la variable $h_job_args{word_length} avec la valeur correspondant a l'identity threshold

=cut

